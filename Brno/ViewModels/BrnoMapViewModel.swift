import SwiftUI
import MapKit
import CoreLocation

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

    // MARK: - Filtering

    func filteredStations(_ all: [KontejnerStation]) -> [KontejnerStation] {
        all.filter { station in
            selectedFilters.isEmpty || selectedFilters.contains { station.matches($0) }
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

    // MARK: - Quick navigation (find nearest)

    func startQuickNavigation(for filter: KomoditaFilter, in stations: [KontejnerStation], userLocation: CLLocation) {
        let base = activeSearchPoint ?? userLocation.coordinate
        if let nearest = findNearest(to: base, for: filter, in: stations) {
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
