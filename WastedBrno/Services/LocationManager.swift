import Foundation
import CoreLocation
import os

// MARK: - Location Manager
// Manages the user's GPS location and determines if they are in Brno.
// Key behaviour:
//   - If user is within 15 km of Brno centre → isInBrno = true, use real GPS
//   - If user is outside Brno (or no GPS) → fallback to Brno centre coordinates
// Used by: BrnoView (map camera positioning), BrnoMapViewModel (route origin)

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let logger = Logger(subsystem: "com.WastedBrno", category: "Location")

    /// Brno city centre — used as the fallback when user is not in Brno or GPS is unavailable.
    static let defaultBrnoCoordinate = CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)

    /// Radius around Brno centre (15 km) — if user is within this, isInBrno = true.
    private static let brnoRadius: CLLocationDistance = 15_000

    /// The system location manager that talks to GPS hardware.
    private let manager = CLLocationManager()

    /// Latest GPS coordinate received from the device. Nil until first fix.
    @Published var lastLocation: CLLocation?

    /// Street name at the user's current position (reverse geocoded). Empty until first fix in Brno.
    @Published var currentStreetName: String = ""

    /// True if the user's last known location is within 15 km of Brno centre.
    @Published var isInBrno: Bool = false

    /// Returns the user's real location if they're in Brno, otherwise Brno centre.
    /// This is the main property that the rest of the app uses as "where is the user".
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
        // Don't start updates here — wait for authorization callback below
    }

    // MARK: - CLLocationManagerDelegate

    /// Called when the user grants or denies location permission.
    /// We only start GPS updates after permission is granted.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("📍 Location authorized — starting updates")
            manager.startUpdatingLocation()
        case .denied, .restricted:
            logger.warning("⚠️ Location access denied")
        case .notDetermined:
            logger.info("📍 Location permission not determined yet")
        @unknown default:
            break
        }
    }

    /// Called every time a new GPS coordinate arrives from the device.
    /// Updates lastLocation, checks if user is in Brno, and reverse-geocodes the street name.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location

        let brnoCenter = CLLocation(latitude: Self.defaultBrnoCoordinate.latitude,
                                    longitude: Self.defaultBrnoCoordinate.longitude)
        isInBrno = location.distance(from: brnoCenter) <= Self.brnoRadius

        guard isInBrno else { return }

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error {
                self?.logger.error("❌ Reverse geocoding failed: \(error.localizedDescription)")
                return
            }
            if let street = placemarks?.first?.thoroughfare {
                DispatchQueue.main.async { self?.currentStreetName = street }
            }
        }
    }

    /// Called when GPS fails (e.g. no signal, airplane mode).
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("❌ Location update failed: \(error.localizedDescription)")
    }
}
