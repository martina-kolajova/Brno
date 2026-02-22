import Foundation
import CoreLocation

// MARK: - Location Manager

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let defaultBrnoCoordinate = CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
    private static let brnoRadius: CLLocationDistance = 15_000 // ~15 km

    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var currentStreetName: String = ""
    @Published var isInBrno: Bool = false

    /// Returns the user's real location if they're in Brno, otherwise Brno center.
    var effectiveLocation: CLLocation {
        if isInBrno, let real = lastLocation {
            return real
        }
        return CLLocation(latitude: Self.defaultBrnoCoordinate.latitude,
                          longitude: Self.defaultBrnoCoordinate.longitude)
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location

        let brnoCenter = CLLocation(latitude: Self.defaultBrnoCoordinate.latitude,
                                    longitude: Self.defaultBrnoCoordinate.longitude)
        isInBrno = location.distance(from: brnoCenter) <= Self.brnoRadius

        guard isInBrno else { return }

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let street = placemarks?.first?.thoroughfare {
                DispatchQueue.main.async { self?.currentStreetName = street }
            }
        }
    }
}
