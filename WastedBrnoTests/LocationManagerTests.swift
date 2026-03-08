import XCTest
import CoreLocation
@testable import WastedBrno

// MARK: - LocationManager Tests
// These tests verify the correct behaviour of the LocationManager class,
// which decides whether the user is in Brno or not,
// and returns either the real GPS location or the Brno city centre as a fallback.

final class LocationManagerTests: XCTestCase {

    // sut = "System Under Test" — standard naming convention for the class being tested
    var sut: LocationManager!

    // setUp() runs BEFORE every test — creates a fresh instance
    override func setUp() {
        super.setUp()
        sut = LocationManager()
    }

    // tearDown() runs AFTER every test — destroys the instance so tests stay isolated
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Default coordinate
    // Verifies that the fallback coordinate is correctly set to Brno city centre

    func testDefaultCoordinateIsBrnoCentre() {
        // Load the static fallback coordinate from the class
        let coord = LocationManager.defaultBrnoCoordinate
        // Check that it matches Brno city centre (accuracy to 3 decimal places)
        XCTAssertEqual(coord.latitude,  49.1951, accuracy: 0.001)
        XCTAssertEqual(coord.longitude, 16.6068, accuracy: 0.001)
    }

    // MARK: - effectiveLocation fallback (no GPS fix yet)
    // Verifies that when the app has no GPS, it returns Brno city centre

    func testEffectiveLocationFallsBackToBrnoWhenNoLocationReceived() {
        // Default state: lastLocation = nil, isInBrno = false (no GPS received yet)
        let effective = sut.effectiveLocation
        // We expect the fallback location — Brno city centre — to be returned
        XCTAssertEqual(
            effective.coordinate.latitude,
            LocationManager.defaultBrnoCoordinate.latitude,
            accuracy: 0.001,
            "Should fall back to Brno centre latitude when no GPS fix"
        )
        XCTAssertEqual(
            effective.coordinate.longitude,
            LocationManager.defaultBrnoCoordinate.longitude,
            accuracy: 0.001,
            "Should fall back to Brno centre longitude when no GPS fix"
        )
    }

    // MARK: - isInBrno + effectiveLocation when inside Brno
    // Verifies that when the user is in Brno, their real GPS location is returned

    func testEffectiveLocationReturnsRealLocationWhenInsideBrno() {
        // Simulate a GPS update — user is standing at Náměstí Svobody in Brno
        let brnoLocation = CLLocation(latitude: 49.1952, longitude: 16.6079)
        sut.lastLocation = brnoLocation  // set the real location
        sut.isInBrno = true              // mark that we are in Brno

        let effective = sut.effectiveLocation
        // We expect the exact real GPS location to be returned, not the fallback
        XCTAssertEqual(effective.coordinate.latitude,  brnoLocation.coordinate.latitude,  accuracy: 0.0001)
        XCTAssertEqual(effective.coordinate.longitude, brnoLocation.coordinate.longitude, accuracy: 0.0001)
    }

    // MARK: - isInBrno + effectiveLocation when outside Brno
    // Verifies that when the user is outside Brno, Brno centre is returned (not their real location)

    func testEffectiveLocationFallsBackToBrnoWhenOutsideBrno() {
        // Simulate a GPS update — user is in Prague (~190 km from Brno)
        let pragueLocation = CLLocation(latitude: 50.0755, longitude: 14.4378)
        sut.lastLocation = pragueLocation  // set Prague as the current location
        sut.isInBrno = false               // mark that we are NOT in Brno

        let effective = sut.effectiveLocation
        // We expect Brno centre to be returned, not Prague
        XCTAssertEqual(
            effective.coordinate.latitude,
            LocationManager.defaultBrnoCoordinate.latitude,
            accuracy: 0.001,
            "When outside Brno, effectiveLocation must return Brno centre"
        )
        XCTAssertEqual(
            effective.coordinate.longitude,
            LocationManager.defaultBrnoCoordinate.longitude,
            accuracy: 0.001
        )
    }

    // MARK: - Distance-based isInBrno logic
    // Verifies that the 15 km radius around Brno centre works correctly

    func testLocationInsideBrnoRadius() {
        // Brno centre has distance 0 from itself — must be inside the radius
        let brnoCenter = CLLocation(
            latitude: LocationManager.defaultBrnoCoordinate.latitude,
            longitude: LocationManager.defaultBrnoCoordinate.longitude
        )
        let distance = brnoCenter.distance(from: CLLocation(
            latitude: LocationManager.defaultBrnoCoordinate.latitude,
            longitude: LocationManager.defaultBrnoCoordinate.longitude
        ))
        // Distance must be less than or equal to 15 000 metres
        XCTAssertLessThanOrEqual(distance, 15_000, "Brno centre must be within the 15 km radius")
    }

    func testLocationOutsideBrnoRadius() {
        // Prague is approximately 190 km from Brno — must be outside the radius
        let prague = CLLocation(latitude: 50.0755, longitude: 14.4378)
        let brnoCenter = CLLocation(
            latitude: LocationManager.defaultBrnoCoordinate.latitude,
            longitude: LocationManager.defaultBrnoCoordinate.longitude
        )
        let distance = prague.distance(from: brnoCenter)
        // Distance must be greater than 15 000 metres
        XCTAssertGreaterThan(distance, 15_000, "Prague should be outside the 15 km Brno radius")
    }

    func testLocationOnEdgeOfBrnoRadius() {
        // A point ~15 km north of Brno centre — should lie just beyond the boundary
        let edgeLocation = CLLocation(latitude: 49.330, longitude: 16.6068)
        let brnoCenter = CLLocation(
            latitude: LocationManager.defaultBrnoCoordinate.latitude,
            longitude: LocationManager.defaultBrnoCoordinate.longitude
        )
        let distance = edgeLocation.distance(from: brnoCenter)
        // Radius is 15 000 m — verify that this point is outside the boundary
        XCTAssertGreaterThan(distance, 15_000, "A point ~15 km north should lie outside the Brno radius")
    }

    // MARK: - Initial state
    // Verifies that all values are in their default empty state on launch

    func testInitialStateHasNoLocation() {
        // On init, no GPS signal has been received yet → lastLocation must be nil
        XCTAssertNil(sut.lastLocation, "lastLocation should be nil before any GPS fix")
    }

    func testInitialIsInBrnoIsFalse() {
        // On init, we don't know where we are yet → isInBrno must be false
        XCTAssertFalse(sut.isInBrno, "isInBrno should be false before any GPS fix")
    }

    func testInitialStreetNameIsEmpty() {
        // On init, no reverse geocoding has run yet → street name must be empty
        XCTAssertEqual(sut.currentStreetName, "", "currentStreetName should be empty on init")
    }
}
