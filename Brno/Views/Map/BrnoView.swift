import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map View

struct BrnoView: View {
    let allStations: [KontejnerStation]

    @StateObject private var vm = BrnoMapViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()

    @State private var streetQuery: String = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
            controlsLayer
            floatingButtons

            // Quick nav sheet overlaid at bottom
            if vm.showNavigationPanel {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35)) {
                            vm.showNavigationPanel = false
                        }
                    }

                QuickNavButtons(
                    onSelect: { filter in
                        withAnimation(.spring(response: 0.35)) {
                            vm.showNavigationPanel = false
                        }
                        vm.startQuickNavigation(for: filter, in: allStations, userLocation: locationManager.effectiveLocation)
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.35)) {
                            vm.showNavigationPanel = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 0)
                .zIndex(20)
            }
        }
        .animation(.spring(response: 0.35), value: vm.showNavigationPanel)
        .onChange(of: streetQuery) { newValue in
            if isSearchFocused { searchCompleter.update(query: newValue) }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $vm.camera) {
            // Show pins only when a filter is active
            if !vm.selectedFilters.isEmpty {
                ForEach(vm.filteredStations(allStations)) { st in
                    Annotation(st.ulice, coordinate: st.coordinate) {
                        PiePinView(
                            station: st,
                            activeFilters: vm.selectedFilters,
                            isSelected: vm.selectedStation?.id == st.id,
                            spanDelta: vm.mapRegion.span.latitudeDelta
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isSearchFocused = false
                                vm.selectStation(st)
                            }
                        }
                    }
                }
            }

            if let searchPoint = vm.activeSearchPoint {
                Annotation("Search point", coordinate: searchPoint) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white))
                        .shadow(radius: 3)
                }
            }

            if let route = vm.route {
                MapPolyline(route.polyline)
                    .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            // Always show the blue GPS dot
            UserAnnotation()
        }
        .mapStyle(.standard)
        .onMapCameraChange { context in
            vm.mapRegion = context.region
        }
        .ignoresSafeArea()
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
            .onAppear { vm.detent = .fraction(0.37) }
        }
    }

    // MARK: - Top controls

    private var controlsLayer: some View {
        VStack(spacing: 0) {
            FiltersBar(selected: $vm.selectedFilters, streetQuery: $streetQuery)
                .focused($isSearchFocused)
                .padding(.top, 10)

            if isSearchFocused && !searchCompleter.results.isEmpty {
                searchSuggestions
            }

            Spacer()
        }
    }

    // MARK: - Search suggestions

    private var searchSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(searchCompleter.results, id: \.self) { result in
                    Button {
                        vm.selectAddress(result)
                        streetQuery = result.title
                        isSearchFocused = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title).foregroundStyle(.red)
                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal, 20)
        .padding(.top, 5)
        .frame(maxHeight: 200)
    }

    // MARK: - Floating action buttons

    private var floatingButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    // Trash / find nearest
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.showNavigationPanel.toggle()
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(vm.showNavigationPanel ? .red : .white)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(vm.showNavigationPanel ? .white : .red)
                                    .shadow(color: .black.opacity(0.15), radius: 4)
                            )
                    }
                    .scaleEffect(vm.showNavigationPanel ? 0.95 : 1.0)

                    // Location arrow — toggles color, centers on user or Brno
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.isTracking.toggle()
                        }
                        let coord = locationManager.isInBrno
                            ? locationManager.effectiveLocation.coordinate
                            : LocationManager.defaultBrnoCoordinate
                        withAnimation(.spring()) {
                            vm.camera = .region(MKCoordinateRegion(
                                center: coord,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            ))
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundStyle(vm.isTracking ? .red : .white)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(vm.isTracking ? .white : .red)
                                    .shadow(color: .black.opacity(0.15), radius: 4)
                            )
                    }
                    .scaleEffect(vm.isTracking ? 0.95 : 1.0)
                }
                .padding(.trailing, 20)
                .padding(.bottom, vm.selectedStation == nil ? 40 : 320)
            }
        }
        .zIndex(10)
    }
}
