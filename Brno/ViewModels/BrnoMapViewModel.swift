import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Map ViewModel

@MainActor
final class BrnoMapViewModel: ObservableObject {

    // MARK: - Map state

    @Published var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: LocationManager.defaultBrnoCoordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @Published var mapRegion = MKCoordinateRegion(
        center: LocationManager.defaultBrnoCoordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    // MARK: - Selection & route

    @Published var selectedStation: KontejnerStation?
    @Published var route: MKRoute?
    @Published var routeDistance = ""
    @Published var routeTravelTime = ""
    @Published var detent: PresentationDetent = .height(70)

    // MARK: - User tracking

    @Published var isTracking: Bool = false

    // MARK: - Search & filters

    @Published var selectedFilters: Set<KomoditaFilter> = []
    @Published var activeSearchPoint: CLLocationCoordinate2D?
    @Published var showNavigationPanel = false

    // MARK: - Navigation state

    @Published var isNavigating: Bool = false
    @Published var activeNavFilter: KomoditaFilter? = nil

    // MARK: - Visible stations (pre-filtered, capped, background-computed)

    @Published var visibleStations: [KontejnerStation] = []
    private let maxAnnotations = 200
    private var allStationsCache: [KontejnerStation] = []
    private var filterTask: Task<Void, Never>?
    private var regionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounce region/filter changes — recompute after 250ms of no changes
        regionSubject
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.recomputeVisibleStations() }
            .store(in: &cancellables)
    }

    /// Call once when stations are loaded.
    func setAllStations(_ stations: [KontejnerStation]) {
        allStationsCache = stations
        triggerRecompute()
    }

    /// Called on every map camera change.
    func onRegionChanged(_ region: MKCoordinateRegion) {
        mapRegion = region
        triggerRecompute()
    }

    /// Triggers a debounced recompute of visible stations.
    func triggerRecompute() {
        regionSubject.send()
    }

    /// Combines selected filter chips + active nav filter.
    var effectiveFilters: Set<KomoditaFilter> {
        var filters = selectedFilters
        if let nav = activeNavFilter { filters.insert(nav) }
        return filters
    }

    // MARK: - Background filtering

    private func recomputeVisibleStations() {
        filterTask?.cancel()

        let filters = effectiveFilters
        let region = mapRegion
        let stations = allStationsCache
        let cap = maxAnnotations

        // No filters active → empty map (no pins)
        guard !filters.isEmpty else {
            visibleStations = []
            return
        }

        filterTask = Task.detached(priority: .userInitiated) { [weak self] in
            // 1. Bounding box — only stations visible on screen
            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLon = region.center.longitude - region.span.longitudeDelta / 2
            let maxLon = region.center.longitude + region.span.longitudeDelta / 2

            let result = stations.filter { st in
                guard !Task.isCancelled else { return false }
                let lat = st.coordinate.latitude
                let lon = st.coordinate.longitude
                let inBounds = lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
                guard inBounds else { return false }
                return filters.contains { st.matches($0) }
            }

            // 2. Cap to prevent UI overload
            let capped = result.count > cap ? Array(result.prefix(cap)) : result

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?.visibleStations = capped
            }
        }
    }

    // MARK: - Station selection

    func selectStation(_ station: KontejnerStation) {
        selectedStation = station
        route = nil
        routeDistance = ""
        withAnimation(.spring()) {
            camera = .region(MKCoordinateRegion(
                center: station.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    func clearStation() {
        selectedStation = nil
        route = nil
        routeDistance = ""
        routeTravelTime = ""
    }

    func stopNavigation() {
        route = nil
        routeDistance = ""
        routeTravelTime = ""
        selectedStation = nil
        isNavigating = false
        activeNavFilter = nil
        activeSearchPoint = nil
        withAnimation(.spring()) {
            camera = .region(MKCoordinateRegion(
                center: LocationManager.defaultBrnoCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    // MARK: - Address search

    func selectAddress(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { [weak self] response, _ in
            guard let self, let coord = response?.mapItems.first?.placemark.coordinate else { return }
            self.activeSearchPoint = coord
            withAnimation(.spring()) {
                self.camera = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
            }
        }
    }

    /// Clears the search point so user location is used again as the origin.
    func clearSearchPoint() {
        activeSearchPoint = nil
    }

    // MARK: - Quick navigation (find nearest)

    func startQuickNavigation(for filter: KomoditaFilter, in stations: [KontejnerStation], userLocation: CLLocation) {
        let base = activeSearchPoint ?? userLocation.coordinate
        if let nearest = findNearest(to: base, for: filter, in: stations) {
            activeNavFilter = filter
            isNavigating = true
            selectStation(nearest)
            showNavigationPanel = false
        }
    }

    // MARK: - Route calculation

    func calculateRoute(to destination: CLLocationCoordinate2D, userLocation: CLLocation) {
        let start = activeSearchPoint ?? userLocation.coordinate

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        Task {
            do {
                let response = try await MKDirections(request: request).calculate()
                guard let computedRoute = response.routes.first else { return }

                withAnimation(.spring()) {
                    self.route = computedRoute

                    let dist = computedRoute.distance
                    self.routeDistance = dist < 1000
                        ? "\(Int(dist)) m"
                        : String(format: "%.1f km", dist / 1000)
                    self.routeTravelTime = "\(Int(computedRoute.expectedTravelTime / 60)) min"

                    let base = MKCoordinateRegion(computedRoute.polyline.boundingMapRect)
                    self.camera = .region(MKCoordinateRegion(
                        center: base.center,
                        span: MKCoordinateSpan(
                            latitudeDelta: base.span.latitudeDelta * 1.45,
                            longitudeDelta: base.span.longitudeDelta * 1.45
                        )
                    ))
                }
            } catch {
                print("Route error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    private func findNearest(to center: CLLocationCoordinate2D, for filter: KomoditaFilter, in stations: [KontejnerStation]) -> KontejnerStation? {
        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return stations
            .filter { $0.matches(filter) }
            .min {
                let d1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                let d2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                return centerLoc.distance(from: d1) < centerLoc.distance(from: d2)
            }
    }
}
