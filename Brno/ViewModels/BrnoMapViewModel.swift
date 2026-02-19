//
//  BrnoMapViewModel.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.
//
import SwiftUI
import MapKit
import CoreLocation

@MainActor
class BrnoMapViewModel: ObservableObject {
    
    // MARK: - Map state
    @Published var camera: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )))
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // MARK: - Selection & route
    @Published var selectedStation: KontejnerStation? = nil
    @Published var route: MKRoute? = nil
    @Published var routeDistance: String = ""
    @Published var routeTravelTime: String = ""
    
    // MARK: - Search & filters
    @Published var selectedFilters: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
    @Published var activeSearchPoint: CLLocationCoordinate2D? = nil
    @Published var showNavigationPanel = false
    @Published var detent: PresentationDetent = .height(70)
    
    // MARK: - Filtered stations
    func filteredStations(_ all: [KontejnerStation]) -> [KontejnerStation] {
        all.filter { station in
            selectedFilters.isEmpty || selectedFilters.contains { station.matches($0) }
        }
    }
    
    // MARK: - Station selection
    func selectStation(_ st: KontejnerStation) {
        selectedStation = st
        route = nil
        routeDistance = ""
        withAnimation(.spring()) {
            camera = .region(MKCoordinateRegion(
                center: st.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }
    
    func clearStation() {
        selectedStation = nil
    }
    
    func findNearest(to center: CLLocationCoordinate2D, for filter: KomoditaFilter, in stations: [KontejnerStation]) -> KontejnerStation? {
        let filtered = stations.filter { $0.matches(filter) }
        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return filtered.min(by: {
            let loc1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let loc2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return centerLoc.distance(from: loc1) < centerLoc.distance(from: loc2)
        })
    }

    // MARK: - Center on user
    func centerOnUser(location: CLLocation) {
        activeSearchPoint = nil
        withAnimation(.spring()) {
            camera = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    // MARK: - Select address from search
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

    // MARK: - Quick navigation
    func startQuickNavigation(for filter: KomoditaFilter, in stations: [KontejnerStation], userLocation: CLLocation?) {
        let base = activeSearchPoint
            ?? userLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
        if let nearest = findNearest(to: base, for: filter, in: stations) {
            selectStation(nearest)
            showNavigationPanel = false
        }
    }

    // MARK: - Route calculation
    func calculateRoute(to destination: CLLocationCoordinate2D, userLocation: CLLocation?) {
        let start = activeSearchPoint
            ?? userLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)

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
}
//
//@MainActor
//class BrnoMapViewModel: ObservableObject {
//    // MARK: - State (Původně v BrnoView)
//    @Published var selectedFilters: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
//    @Published var streetQuery: String = ""
//    @Published var showNavigationPanel = false
//    @Published var selectedStation: KontejnerStation? = nil
//    @Published var route: MKRoute? = nil
//    @Published var routeDistance: String = ""
//    @Published var routeTravelTime: String = ""
//    @Published var activeSearchPoint: CLLocationCoordinate2D? = nil
//    
//    // Kamera a Region
//    @Published var camera: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//    )))
//    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//    )
//
//    // MARK: - Logika funkcí
//
//    func findMe(locationManager: LocationManager) {
//        guard let userLoc = locationManager.lastLocation else { return }
//        activeSearchPoint = nil
//        withAnimation(.spring()) {
//            camera = .region(MKCoordinateRegion(center: userLoc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
//        }
//    }
//
//    func selectRealAddress(_ completion: MKLocalSearchCompletion) {
//        let searchRequest = MKLocalSearch.Request(completion: completion)
//        let search = MKLocalSearch(request: searchRequest)
//        search.start { [weak self] response, _ in
//            guard let self = self, let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
//            Task { @MainActor in
//                self.activeSearchPoint = coordinate
//                self.streetQuery = completion.title
//                withAnimation(.spring()) {
//                    self.camera = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
//                }
//            }
//        }
//    }
//
//    func selectStation(_ st: KontejnerStation) {
//        withAnimation(.spring()) {
//            selectedStation = st
//            route = nil
//            routeDistance = ""
//        }
//    }
//
//    func startQuickNavigation(for filter: KomoditaFilter, allStations: [KontejnerStation], locationManager: LocationManager) {
//        let basePoint = activeSearchPoint ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
//        if let nearest = findNearest(to: basePoint, for: filter, in: allStations) {
//            selectStation(nearest)
//            showNavigationPanel = false
//        }
//    }
//
//    func calculateRoute(to destination: CLLocationCoordinate2D, locationManager: LocationManager) {
//        let startPoint = activeSearchPoint ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPoint))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
//        request.transportType = .walking
//
//        Task {
//            do {
//                let response = try await MKDirections(request: request).calculate()
//                if let computedRoute = response.routes.first {
//                    self.route = computedRoute
//                    let dist = computedRoute.distance
//                    self.routeDistance = dist < 1000 ? "\(Int(dist)) m" : String(format: "%.1f km", dist / 1000)
//                    self.routeTravelTime = "\(Int(computedRoute.expectedTravelTime / 60)) min"
//
//                    let baseRegion = MKCoordinateRegion(computedRoute.polyline.boundingMapRect)
//                    let paddedRegion = MKCoordinateRegion(
//                        center: baseRegion.center,
//                        span: MKCoordinateSpan(latitudeDelta: baseRegion.span.latitudeDelta * 1.45, longitudeDelta: baseRegion.span.longitudeDelta * 1.45)
//                    )
//                    withAnimation(.spring()) {
//                        self.camera = .region(paddedRegion)
//                    }
//                }
//            } catch { print("Chyba trasy: \(error.localizedDescription)") }
//        }
//    }
//
//    func findNearest(to center: CLLocationCoordinate2D, for filter: KomoditaFilter, in stations: [KontejnerStation]) -> KontejnerStation? {
//        let filtered = stations.filter { $0.matches(filter) }
//        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
//        return filtered.min(by: {
//            let loc1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
//            let loc2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
//            return centerLoc.distance(from: loc1) < centerLoc.distance(from: loc2)
//        })
//    }
//}
