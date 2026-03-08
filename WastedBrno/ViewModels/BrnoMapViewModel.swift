import SwiftUI
import MapKit
import CoreLocation
import Combine
import os

// MARK: - Map ViewModel
// This is the "brain" behind the map screen.
// It manages the camera position, filtering of waste stations,
// route calculation, search, and quick navigation.
// Marked @MainActor so all UI-bound properties are safely updated on the main thread.

@MainActor
final class BrnoMapViewModel: ObservableObject {

    /// Logger for map interactions, filtering, and route calculation.
    private let logger = Logger(subsystem: "com.WastedBrno", category: "MapViewModel")

    // MARK: - Map state
    // Controls what part of the map the user sees.

    /// Restricts the map camera so the user can only pan/zoom
    /// within ~15 km of Brno's city centre — keeps the app focused
    /// on the area where waste stations actually exist.
    static let cameraBounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: LocationManager.defaultBrnoCoordinate,
            latitudinalMeters: 30_000,   // 15 km radius → 30 km total span
            longitudinalMeters: 30_000
        ),
        minimumDistance: 500,    // closest zoom allowed (metres of visible ground)
        maximumDistance: 50_000  // furthest zoom allowed
    )

    /// The current camera position shown on the map (bound two-way with the Map view).
    @Published var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: LocationManager.defaultBrnoCoordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))

    /// Tracks the currently visible region — updated every time the user scrolls/zooms.
    /// Used to decide which stations fall inside the visible area.
    @Published var mapRegion = MKCoordinateRegion(
        center: LocationManager.defaultBrnoCoordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    // MARK: - Selection & route
    // State related to tapping a station and showing a walking route.

    /// The station the user tapped on (shown in the detail sheet).
    @Published var selectedStation: WasteStation?

    /// The computed walking route from user/search location to the selected station.
    @Published var route: MKRoute?

    /// Human-readable route info, e.g. "350 m" or "1.2 km".
    @Published var routeDistance = ""

    /// Human-readable walking time, e.g. "5 min".
    @Published var routeTravelTime = ""

    /// Controls the drag position (height) of the detail bottom sheet.
    @Published var detent: PresentationDetent = .height(70)

    // MARK: - Search & filters
    // Controls which waste types are shown and optional address-based search.

    /// The set of active filter chips the user toggled (e.g. "Paper", "Plastic").
    @Published var selectedFilters: Set<WasteFilter> = []

    /// If the user searched for an address, this holds that coordinate.
    /// It overrides the user's GPS location as the "origin" for route/distance calculations.
    @Published var activeSearchPoint: CLLocationCoordinate2D?

    /// Whether the quick-navigation bottom panel is visible.
    @Published var showNavigationPanel = false

    // MARK: - Navigation state
    // Tracks whether the user is actively being navigated to a station.

    /// True while a route is being shown on the map.
    @Published var isNavigating: Bool = false

    /// The filter type used during quick navigation (e.g. "nearest glass container").
    @Published var activeNavFilter: WasteFilter? = nil

    // MARK: - Visible stations (pre-filtered, capped, background-computed)
    // Instead of rendering ALL 1000+ stations at once, we filter them
    // in the background to only those that are (a) on-screen and
    // (b) match the active filters, capped at 200 to keep the UI smooth.

    /// The stations currently displayed as pins on the map.
    @Published var visibleStations: [WasteStation] = []

    /// True while a background filter task is running (can show a spinner).
    @Published var isRecomputing: Bool = false

    /// Maximum number of pins rendered at once to prevent lag.
    private let maxAnnotations = 200

    /// Full list of all stations loaded from the API — never changes after initial load.
    private var allStationsCache: [WasteStation] = []

    /// Reference to the current background filtering task so we can cancel it
    /// when the user scrolls again before the previous filter finishes.
    private var filterTask: Task<Void, Never>?

    /// Used to debounce rapid region changes (e.g. during a pinch-zoom gesture).
    private var regionSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to the region subject with a 100ms debounce.
        // This means we only re-filter stations 100ms after the user
        // *stops* scrolling/zooming, avoiding unnecessary work mid-gesture.
        regionSubject
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.recomputeVisibleStations() }
            .store(in: &cancellables)
    }

    /// Called once when stations are first loaded from the API.
    /// Stores them and kicks off the initial filter.
    func setAllStations(_ stations: [WasteStation]) {
        allStationsCache = stations
        logger.info("🗺️ Map received \(stations.count) stations")
        triggerRecompute()
    }

    /// Called on every map camera change (scroll/zoom).
    /// Saves the new region and schedules a debounced recompute.
    func onRegionChanged(_ region: MKCoordinateRegion) {
        mapRegion = region
        triggerRecompute()
    }

    /// Sends a signal to the debounced pipeline to recompute visible stations.
    func triggerRecompute() {
        regionSubject.send()
    }

    /// Merges the user's manual filter chips with the quick-nav filter (if any).
    var effectiveFilters: Set<WasteFilter> {
        var filters = selectedFilters
        if let nav = activeNavFilter { filters.insert(nav) }
        return filters
    }

    // MARK: - Background filtering
    // Performance-critical: filters 1000+ stations on a background thread.
    //
    // Algorithm (easy to explain in interview):
    //   1. Cancel any previous filter task (user may still be scrolling)
    //   2. Single pass through all stations:
    //      - Is it inside the visible map rectangle? (bounding box check)
    //      - Does it match at least one active filter? (contains check)
    //   3. Stop at 200 pins (early break — never processes more than needed)
    //   4. Write result back to main thread → SwiftUI updates the map
    //
    // Why this is fast:
    //   - O(n) single pass, no sorting, no grouping, no dictionaries
    //   - Early exit at cap — best case processes only 200 stations
    //   - Debounced by 100ms — doesn't fire during mid-scroll
    //   - Background thread — UI stays at 60fps during filtering

    private func recomputeVisibleStations() {
        filterTask?.cancel()

        let filters = effectiveFilters
        let region = mapRegion
        let stations = allStationsCache
        let cap = maxAnnotations

        guard !filters.isEmpty else {
            visibleStations = []
            isRecomputing = false
            return
        }

        isRecomputing = true

        filterTask = Task.detached(priority: .userInitiated) { [weak self] in

            // Bounding box of the visible map area
            let minLat = region.center.latitude - region.span.latitudeDelta / 2
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2
            let minLon = region.center.longitude - region.span.longitudeDelta / 2
            let maxLon = region.center.longitude + region.span.longitudeDelta / 2

            // Single pass: check bounds + filter match, stop at 200
            var result = [WasteStation]()
            result.reserveCapacity(cap)

            for st in stations {
                if Task.isCancelled { return }            // stop early if a new filter task started
                guard result.count < cap else { break }   // early exit at cap
                let lat = st.coordinate.latitude
                let lon = st.coordinate.longitude
                guard lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon else { continue }
                guard filters.contains(where: { st.matches($0) }) else { continue }
                result.append(st)
            }

            guard !Task.isCancelled else { return }

            let captured = result
            guard let strongSelf = self else { return }
            await MainActor.run {
                strongSelf.visibleStations = captured
                strongSelf.isRecomputing = false
            }
        }
    }

    // MARK: - Station selection
    // Handles tapping a pin on the map.

    /// Selects a station: stores it, clears any old route, and zooms the camera to it.
    func selectStation(_ station: WasteStation) {
        selectedStation = station
        route = nil
        routeDistance = ""
        routeTravelTime = ""
        withAnimation(.easeInOut(duration: 0.4)) {
            camera = .region(MKCoordinateRegion(
                center: station.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    /// Deselects the current station and clears all route + navigation state.
    /// Does NOT zoom out — the user stays where they are on the map.
    func clearStation() {
        selectedStation = nil
        route = nil
        routeDistance = ""
        routeTravelTime = ""
        isNavigating = false
        activeNavFilter = nil
        // NOTE: activeSearchPoint is intentionally NOT cleared here
        // so the "Tady nejsu" search pin stays visible after dismissing the detail panel.
        // It is only cleared by stopNavigation() or clearSearchPoint().
        triggerRecompute()
    }

    /// Ends active navigation AND zooms back to the default Brno overview.
    /// Called by the zoom-out button on the map.
    func stopNavigation() {
        clearStation()
        activeSearchPoint = nil   // ← clear search pin only on full stop/zoom-out
        withAnimation(.easeInOut(duration: 0.4)) {
            camera = .region(MKCoordinateRegion(
                center: LocationManager.defaultBrnoCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    // MARK: - Address search
    // Lets the user type a street name and jump to that location.

    /// Takes a search completion result, geocodes it, and moves the camera there.
    /// Uses async/await to ensure all @Published property updates happen on @MainActor.
    func selectAddress(_ completion: MKLocalSearchCompletion) {
        // Clear any previous station selection, route, and navigation state
        // so the detail panel from a previous find is dismissed first.
        clearStation()

        Task { @MainActor in
            let request = MKLocalSearch.Request(completion: completion)
            do {
                let response = try await MKLocalSearch(request: request).start()
                guard let coord = response.mapItems.first?.placemark.coordinate else {
                    self.logger.warning("⚠️ Geocoding returned no results")
                    return
                }
                logger.info("🔍 Address found: \(coord.latitude), \(coord.longitude)")
                self.activeSearchPoint = coord
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.camera = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                }
            } catch {
                logger.error("❌ Address geocoding failed: \(error.localizedDescription)")
            }
        }
    }

    /// Clears the search point so user's GPS location is used as origin again.
    func clearSearchPoint() {
        activeSearchPoint = nil
    }

    // MARK: - Quick navigation (find nearest)
    // One-tap feature: finds the closest station of a given waste type.

    /// Finds the nearest station matching `filter` and selects it.
    /// Uses the search point (if set) or the user's live GPS as the origin.
    func startQuickNavigation(for filter: WasteFilter, in stations: [WasteStation], userLocation: CLLocation) {
        let base = activeSearchPoint ?? userLocation.coordinate
        if let nearest = findNearest(to: base, for: filter, in: stations) {
            activeNavFilter = filter
            isNavigating = true
            selectStation(nearest)
            showNavigationPanel = false
        } else {
            logger.warning("⚠️ No station found matching filter: \(filter.displayName)")
            showNavigationPanel = false
        }
    }

    // MARK: - Route calculation
    // Computes a walking route from the origin to a destination station using Apple Maps directions.

    /// Calculates a walking route from the user's position (or search point) to a station.
    /// Updates route, routeDistance, routeTravelTime, and zooms the camera to fit the route.
    func calculateRoute(to destination: CLLocationCoordinate2D, userLocation: CLLocation) {
        // Use search point if available, otherwise fall back to GPS.
        let start = activeSearchPoint ?? userLocation.coordinate

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking  // walking directions (waste stations are local)

        Task {
            do {
                let response = try await MKDirections(request: request).calculate()
                guard let computedRoute = response.routes.first else {
                    self.logger.warning("⚠️ No walking route found")
                    return
                }

                withAnimation(.easeInOut(duration: 0.4)) {
                    self.route = computedRoute
                    self.isNavigating = true

                    // Format distance as "X m" or "X.X km"
                    let dist = computedRoute.distance
                    self.routeDistance = dist < 1000
                        ? "\(Int(dist)) m"
                        : String(format: "%.1f km", dist / 1000)

                    // Format travel time as "X min"
                    self.routeTravelTime = "\(Int(computedRoute.expectedTravelTime / 60)) min"

                    // Zoom the camera to show the entire route with some padding (1.45×).
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
                logger.error("❌ Route calculation failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    /// Finds the station closest to `center` that matches the given waste `filter`.
    /// Uses straight-line distance (CLLocation.distance) for speed.
    private func findNearest(to center: CLLocationCoordinate2D, for filter: WasteFilter, in stations: [WasteStation]) -> WasteStation? {
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
