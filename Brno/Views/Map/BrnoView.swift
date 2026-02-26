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

            FloatingButtons(
                vm: vm,
                isInBrno: locationManager.isInBrno,
                effectiveLocation: locationManager.effectiveLocation,
                onClearSearch: { streetQuery = "" }
            )

            QuickNavOverlay(
                vm: vm,
                allStations: allStations,
                userLocation: locationManager.effectiveLocation
            )
        }
        .animation(.spring(response: 0.35), value: vm.showNavigationPanel)
        .onAppear { vm.setAllStations(allStations) }
        .onChange(of: streetQuery) { _, newValue in
            if isSearchFocused { searchCompleter.update(query: newValue) }
            if newValue.isEmpty { vm.clearSearchPoint() }
        }
        .onChange(of: vm.selectedFilters) { vm.triggerRecompute() }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $vm.camera) {
            ForEach(vm.visibleStations) { st in
                Annotation(st.nazev, coordinate: st.coordinate) {
                    PieChart(
                        station: st,
                        activeFilters: vm.effectiveFilters,
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

            UserAnnotation()
        }
        .mapStyle(.standard)
        .onMapCameraChange { context in vm.onRegionChanged(context.region) }
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

    // MARK: - Top Controls

    private var controlsLayer: some View {
        VStack(spacing: 0) {
            FiltersBar(selected: $vm.selectedFilters, streetQuery: $streetQuery)
                .focused($isSearchFocused)
                .padding(.top, 10)

            if isSearchFocused && !searchCompleter.results.isEmpty {
                SearchSuggestions(results: searchCompleter.results) { result, title in
                    vm.selectAddress(result)
                    streetQuery = title
                    isSearchFocused = false
                }
            }

            Spacer()
        }
    }
}
