import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map View
// This is the main map screen of the app.
// It layers together: the Apple Map, station pins, filter chips,
// address search, action buttons, and the quick-navigation panel.
// All map logic is delegated to BrnoMapViewModel (MVVM pattern).

struct BrnoView: View {
    /// All waste stations fetched from the API — passed in from the parent (ContentView).
    let allStations: [WasteStation]

    /// Callback to navigate back to the Info screen.
    var onBack: (() -> Void)? = nil

    // MARK: - State objects
    // Each @StateObject is created once and survives view re-renders.

    /// The map view-model — holds camera position, filters, route, selection, etc.
    @StateObject private var vm = BrnoMapViewModel()

    /// Manages GPS permissions and the user's live location.
    @StateObject private var locationManager = LocationManager()

    /// Provides address auto-complete suggestions as the user types.
    @StateObject private var searchCompleter = SearchCompleter()

    /// The current text in the address search bar.
    @State private var streetQuery: String = ""

    /// Animates the dash pattern along the route line.
    @State private var dashPhase: CGFloat = 0

    /// Timer that drives the moving-dash animation (Map content ignores withAnimation).
    @State private var dashTimer: Timer?

    /// Tracks whether the search field is focused (keyboard is open).
    @FocusState private var isSearchFocused: Bool

    // MARK: - Body
    // The view is a ZStack with three layers stacked on top of each other:
    //   1. mapLayer       – the Apple Map with pins, route line, and user dot
    //   2. controlsLayer  – filter chips + search bar + autocomplete suggestions
    //   3. MapActionButtons – floating buttons (locate me, reset, quick-nav)
    //   4. QuickNavPanel   – bottom sheet for "find nearest" one-tap navigation

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
            controlsLayer

            // Floating action buttons (bottom-right): locate user, reset camera, open quick-nav panel.
            MapActionButtons(
                vm: vm,
                isInBrno: locationManager.isInBrno,
                effectiveLocation: locationManager.effectiveLocation,
                onClearSearch: { streetQuery = "" }
            )

            // Slide-up panel that lets the user tap a waste type to find the nearest station.
            QuickNavPanel(
                vm: vm,
                allStations: allStations,
                userLocation: locationManager.effectiveLocation
            )
        }
        .animation(.spring(response: 0.35), value: vm.showNavigationPanel)
        // Pass all stations to the view-model once when this screen appears.
        .onAppear { vm.setAllStations(allStations) }
        // Keep the search completer in sync with the text field.
        .onChange(of: streetQuery) { _, newValue in
            if isSearchFocused { searchCompleter.update(query: newValue) }
            if newValue.isEmpty { vm.clearSearchPoint() }
        }
        // Re-filter pins whenever the user toggles a filter chip.
        .onChange(of: vm.selectedFilters) { vm.triggerRecompute() }
        // Clean up the dash animation timer when this view is removed.
        .onDisappear {
            dashTimer?.invalidate()
            dashTimer = nil
        }
    }

    // MARK: - Map layer
    // The actual Apple Map. Bounded to ~15 km around Brno so the user can't scroll away.

    private var mapLayer: some View {
        Map(position: $vm.camera, bounds: BrnoMapViewModel.cameraBounds) {

            // --- Station pins ---
            // Only the pre-filtered, capped subset is rendered (max 200).
            ForEach(vm.visibleStations) { st in
                Annotation("", coordinate: st.coordinate) {
                    StationPin(
                        station: st,
                        activeFilters: vm.effectiveFilters,
                        isSelected: vm.selectedStation?.id == st.id,
                        spanDelta: vm.mapRegion.span.latitudeDelta
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isSearchFocused = false       // dismiss keyboard
                            vm.selectStation(st)          // zoom in + open detail sheet
                        }
                    }
                }
            }

            // --- Search-point marker ---
            // Shown when the user searched for an address (red pin).
            if let searchPoint = vm.activeSearchPoint {
                Annotation("Tady su", coordinate: searchPoint) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white))
                        .shadow(radius: 3)
                }
            }

            // --- Walking route polyline (dashed + animated) ---
            // Drawn on the map after the user taps "Navigate" in the detail sheet.
            if let route = vm.route {
                MapPolyline(route.polyline)
                    .stroke(
                        .red,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: [8, 6],
                            dashPhase: dashPhase
                        )
                    )
            }

            // --- User's live GPS dot ---
            UserAnnotation()
        }
        .mapStyle(.standard)
        // Every time the user scrolls/zooms, update the view-model's region.
        .onMapCameraChange { context in vm.onRegionChanged(context.region) }
        .ignoresSafeArea()
        // Animate the dash pattern so it flows along the route line.
        // Map content doesn't support withAnimation, so we use a Timer instead.
        .onChange(of: vm.route != nil) { _, hasRoute in
            dashTimer?.invalidate()
            dashTimer = nil
            if hasRoute {
                dashPhase = 0
                dashTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    DispatchQueue.main.async {
                        dashPhase += 1
                    }
                }
            } else {
                dashPhase = 0
            }
        }
        // --- Detail bottom sheet ---
        // Appears when a station is selected; shows station info + "Navigate" button.
        .sheet(item: $vm.selectedStation) { station in
            DetailStationPanel(
                station: station,
                navInfo: vm.routeDistance.isEmpty ? nil : "\(vm.routeDistance) • \(vm.routeTravelTime)",
                onNavigate: { vm.calculateRoute(to: station.coordinate, userLocation: locationManager.effectiveLocation) },
                onClose: { vm.clearStation() },
                detent: $vm.detent
            )
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.scrolls)
            .presentationDetents([.fraction(0.37), .large, .height(70)], selection: $vm.detent)
            .onAppear { vm.detent = .fraction(0.37) }     // open at ~37% height by default
        }
    }

    // MARK: - Top controls layer
    // Filter chips bar + address search field + autocomplete dropdown.

    private var controlsLayer: some View {
        VStack(spacing: 0) {
            // Horizontal row of filter chips (Paper, Plastic, Glass…) + search field.
            FiltersBar(selected: $vm.selectedFilters, streetQuery: $streetQuery, onBack: onBack)
                .focused($isSearchFocused)
                .padding(.top, 10)

            // Autocomplete suggestions — only shown while the search field is focused.
            if isSearchFocused && !searchCompleter.results.isEmpty {
                SearchSuggestions(results: searchCompleter.results) { result, title in
                    vm.selectAddress(result)       // geocode and move camera
                    streetQuery = title             // fill in the search bar
                    isSearchFocused = false         // dismiss keyboard
                }
            }

            Spacer()
        }
    }
}
