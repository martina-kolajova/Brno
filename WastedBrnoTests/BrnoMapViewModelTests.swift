import XCTest
import MapKit
import CoreLocation
@testable import WastedBrno

// Helper factory — creates a test station without repeating the full init every time
private extension WasteStation {
    static func mock(
        id: String = "1",
        nazev: String = "Test Station",
        komodity: [String] = ["Papír"],
        lat: Double = 49.1951,
        lon: Double = 16.6068
    ) -> WasteStation {
        WasteStation(
            id: id,
            nazev: nazev,
            komodity: komodity,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
        )
    }
}

// We are testing BrnoMapViewModel — the class that controls all the logic of the map screen.
// @MainActor = all tests run on the main thread, just like in production.
@MainActor
final class BrnoMapViewModelTests: XCTestCase {

    // sut = "System Under Test" = the instance of the class we are testing
    var sut: BrnoMapViewModel!

    // Runs BEFORE every test — creates a clean ViewModel
    override func setUp() {
        super.setUp()
        sut = BrnoMapViewModel()
    }

    // Runs AFTER every test — destroys the instance so tests don't affect each other
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial state
    // Right after launch everything must be empty — the user hasn't done anything yet

    func testInitialState_noSelectedStation() {
        // User hasn't tapped anything yet → no detail panel should be showing
        XCTAssertNil(sut.selectedStation)
    }

    func testInitialState_noFilters() {
        // User hasn't selected any waste type yet
        XCTAssertTrue(sut.selectedFilters.isEmpty)
    }

    func testInitialState_navigationOff() {
        // Navigation hasn't started yet
        XCTAssertFalse(sut.isNavigating)
    }

    func testInitialState_noRoute() {
        // No route has been calculated yet → distance and time labels are empty
        XCTAssertNil(sut.route)
        XCTAssertEqual(sut.routeDistance, "")
        XCTAssertEqual(sut.routeTravelTime, "")
    }

    func testInitialState_noSearchPin() {
        // User hasn't searched for an address yet → search pin doesn't exist
        XCTAssertNil(sut.activeSearchPoint)
    }

    // MARK: - selectStation (tapping a pin)
    // User taps a pin on the map

    func testSelectStation_savesTheStation() {
        // When the user taps a pin, the ViewModel must remember that station
        let station = WasteStation.mock(id: "42")
        sut.selectStation(station)
        XCTAssertEqual(sut.selectedStation?.id, "42")
    }

    func testSelectStation_clearsOldDistance() {
        // When the user taps a new pin, the old route distance must be cleared
        // — otherwise the detail panel would show data from the previous station
        sut.routeDistance = "500 m"
        sut.selectStation(WasteStation.mock())
        XCTAssertEqual(sut.routeDistance, "")
    }

    func testSelectStation_replacesExistingSelection() {
        // Tapping a second pin replaces the first selection
        sut.selectStation(WasteStation.mock(id: "A"))
        sut.selectStation(WasteStation.mock(id: "B"))
        XCTAssertEqual(sut.selectedStation?.id, "B")
    }

    // MARK: - clearStation (closing the detail panel)
    // User swipes down or taps outside the panel

    func testClearStation_removesSelectedStation() {
        // After closing the panel no station should be selected
        sut.selectStation(WasteStation.mock())
        sut.clearStation()
        XCTAssertNil(sut.selectedStation)
    }

    func testClearStation_clearsRoute() {
        // Route distance and travel time must disappear after closing the panel
        sut.routeDistance = "1 km"
        sut.routeTravelTime = "12 min"
        sut.clearStation()
        XCTAssertEqual(sut.routeDistance, "")
        XCTAssertEqual(sut.routeTravelTime, "")
    }

    func testClearStation_stopsNavigation() {
        // Closing the panel also ends any active navigation
        sut.isNavigating = true
        sut.clearStation()
        XCTAssertFalse(sut.isNavigating)
    }

    func testClearStation_doesNOTClearSearchPin() {
        // IMPORTANT: the "Tady su" search pin must STAY on the map after closing the panel
        // — it is only removed by stopNavigation()
        sut.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.61)
        sut.clearStation()
        XCTAssertNotNil(sut.activeSearchPoint)
    }

    // MARK: - stopNavigation (zoom out / end navigation button)
    // Fully ends navigation — also clears the search pin

    func testStopNavigation_clearsEverything() {
        // stopNavigation clears the station, route, navigation AND the search pin
        sut.selectStation(WasteStation.mock())
        sut.isNavigating = true
        sut.activeNavFilter = .papir
        sut.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.61)

        sut.stopNavigation()

        XCTAssertNil(sut.selectedStation)
        XCTAssertFalse(sut.isNavigating)
        XCTAssertNil(sut.activeNavFilter)
        XCTAssertNil(sut.activeSearchPoint) // ← unlike clearStation(), this IS cleared here
    }

    // MARK: - clearSearchPoint (removing a searched address)

    func testClearSearchPoint_removesThePinFromMap() {
        // User taps X on the search bar → search pin disappears
        sut.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.61)
        sut.clearSearchPoint()
        XCTAssertNil(sut.activeSearchPoint)
    }

    func testClearSearchPoint_whenAlreadyNil_doesNotCrash() {
        // Edge case: clearing an empty search point must not crash the app
        sut.activeSearchPoint = nil
        sut.clearSearchPoint() // must not throw an error
        XCTAssertNil(sut.activeSearchPoint)
    }

    // MARK: - effectiveFilters (active filters)
    // Combines the user's manual filter chips with the quick-nav filter

    func testEffectiveFilters_noNavFilter_returnsOnlySelectedFilters() {
        // Without a quick-nav filter, effectiveFilters returns only the manually selected chips
        sut.selectedFilters = [.papir, .sklo]
        sut.activeNavFilter = nil
        XCTAssertEqual(sut.effectiveFilters, [.papir, .sklo])
    }

    func testEffectiveFilters_withNavFilter_mergesBoth() {
        // Quick-nav adds its filter on top of the manually selected chips
        sut.selectedFilters = [.papir]
        sut.activeNavFilter = .plast
        XCTAssertTrue(sut.effectiveFilters.contains(.papir))
        XCTAssertTrue(sut.effectiveFilters.contains(.plast))
    }

    func testEffectiveFilters_noFilters_mapIsEmpty() {
        // No filters selected = no pins on the map
        sut.selectedFilters = []
        sut.activeNavFilter = nil
        XCTAssertTrue(sut.effectiveFilters.isEmpty)
    }

    // MARK: - startQuickNavigation (find nearest container)
    // One-tap feature: "find the nearest container of this type"

    func testStartQuickNavigation_selectsNearestStation() {
        // Given two paper stations at different distances, the closer one must be selected
        let nearby = WasteStation.mock(id: "nearby", komodity: ["Papír"], lat: 49.1952, lon: 16.6069)
        let far    = WasteStation.mock(id: "far",    komodity: ["Papír"], lat: 49.30,   lon: 16.70)

        let userLocation = CLLocation(latitude: 49.1951, longitude: 16.6068)
        sut.startQuickNavigation(for: .papir, in: [far, nearby], userLocation: userLocation)

        XCTAssertEqual(sut.selectedStation?.id, "nearby")
        XCTAssertTrue(sut.isNavigating)
    }

    func testStartQuickNavigation_noMatch_nothingHappens() {
        // If no station matches the filter, nothing should change
        let station = WasteStation.mock(komodity: ["Papír"]) // only paper, not textil
        let userLocation = CLLocation(latitude: 49.1951, longitude: 16.6068)

        sut.startQuickNavigation(for: .textil, in: [station], userLocation: userLocation)

        XCTAssertNil(sut.selectedStation)
        XCTAssertFalse(sut.isNavigating)
    }

    func testStartQuickNavigation_prefersSearchPointOverGPS() {
        // If the user searched for an address, that is used as the origin — not GPS
        let nearSearch = WasteStation.mock(id: "nearSearch", komodity: ["Papír"], lat: 49.20, lon: 16.65)
        let nearGPS    = WasteStation.mock(id: "nearGPS",    komodity: ["Papír"], lat: 49.1951, lon: 16.6068)

        // Search point is at a different location than GPS
        sut.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.20, longitude: 16.65)
        let gps = CLLocation(latitude: 49.1951, longitude: 16.6068)

        sut.startQuickNavigation(for: .papir, in: [nearSearch, nearGPS], userLocation: gps)

        XCTAssertEqual(sut.selectedStation?.id, "nearSearch", "Search point must be used as origin, not GPS")
    }

    // MARK: - Recompute visible stations (async)
    // The filter pipeline runs in the background with a 100ms debounce

    func testRecompute_withPapirFilter_stationBecomesVisible() async throws {
        // A paper station must be visible when the paper filter is active
        let station = WasteStation.mock(id: "1", komodity: ["Papír"])
        sut.setAllStations([station])
        sut.selectedFilters = [.papir]
        sut.triggerRecompute()

        // Wait 300ms — debounce (100ms) + time for background processing
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertFalse(sut.visibleStations.isEmpty, "Paper station must be visible")
    }

    func testRecompute_noFilters_noPins() async throws {
        // Without an active filter no pins should appear on the map
        sut.setAllStations([WasteStation.mock(id: "1")])
        sut.selectedFilters = []
        sut.triggerRecompute()

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(sut.visibleStations.isEmpty, "No filters = no pins on the map")
    }

    func testRecompute_wrongFilter_stationStaysHidden() async throws {
        // A paper station must NOT appear when the textil filter is active
        let station = WasteStation.mock(id: "1", komodity: ["Papír"])
        sut.setAllStations([station])
        sut.selectedFilters = [.textil]
        sut.triggerRecompute()

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(sut.visibleStations.isEmpty, "Paper station must not appear for textil filter")
    }
}
