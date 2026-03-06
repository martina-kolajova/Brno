import XCTest
import CoreLocation
@testable import WastedBrno

// MARK: - Mock API Service

struct MockKontejneryService: KontejneryServicing {
    var result: (stats: WasteStatistics, stations: [WasteStation]) = (
        WasteStatistics(totalContainers: 0, totalStations: 0, byKind: [:]),
        []
    )
    var shouldFail = false

    func fetchAllData() async throws -> (stats: WasteStatistics, stations: [WasteStation]) {
        if shouldFail { throw ServiceError.httpError(statusCode: 500) }
        return result
    }
}

// MARK: - Test Helpers

extension WasteStation {
    static func mock(
        id: String = "1",
        title: String = "Test Station",
        ulice: String = "Testovací",
        cp: String? = "42",
        komodity: [String] = ["Papír", "Plast"],
        lat: Double = 49.1951,
        lon: Double = 16.6068
    ) -> WasteStation {
        WasteStation(
            id: id,
            title: title,
            ulice: ulice,
            cp: cp,
            komodity: komodity,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
        )
    }
}

// MARK: - Station Matching Tests

final class WasteStationTests: XCTestCase {

    func testMatchesPapir() {
        let station = WasteStation.mock(komodity: ["Papír"])
        XCTAssertTrue(station.matches(.papir))
    }

    func testMatchesPlast() {
        let station = WasteStation.mock(komodity: ["Plast"])
        XCTAssertTrue(station.matches(.plast))
    }

    func testDoesNotMatchWrongFilter() {
        let station = WasteStation.mock(komodity: ["Papír"])
        XCTAssertFalse(station.matches(.sklo))
        XCTAssertFalse(station.matches(.bio))
        XCTAssertFalse(station.matches(.textil))
    }

    func testMatchesMultipleKomodity() {
        let station = WasteStation.mock(komodity: ["Papír", "Sklo", "Textil"])
        XCTAssertTrue(station.matches(.papir))
        XCTAssertTrue(station.matches(.sklo))
        XCTAssertTrue(station.matches(.textil))
        XCTAssertFalse(station.matches(.plast))
    }

    func testDominantFilter() {
        let station = WasteStation.mock(komodity: ["Sklo"])
        XCTAssertEqual(station.dominantFilter(), .sklo)
    }

    func testDominantFilterReturnsFirstMatch() {
        let station = WasteStation.mock(komodity: ["Papír", "Plast"])
        XCTAssertEqual(station.dominantFilter(), .papir)
    }

    func testEmptyKomodityMatchesNothing() {
        let station = WasteStation.mock(komodity: [])
        for filter in WasteFilter.allCases {
            XCTAssertFalse(station.matches(filter))
        }
        XCTAssertNil(station.dominantFilter())
    }
}

// MARK: - AppViewModel Tests

@MainActor
final class AppViewModelTests: XCTestCase {

    func testLoadDataSuccess() async {
        let mockStats = WasteStatistics(totalContainers: 10, totalStations: 3, byKind: [.papir: 5, .sklo: 5])
        let mockStations = [WasteStation.mock(id: "1"), WasteStation.mock(id: "2")]
        let service = MockKontejneryService(result: (mockStats, mockStations))

        let vm = AppViewModel(service: service)
        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.loadError)
        XCTAssertEqual(vm.allStations.count, 2)
        XCTAssertEqual(vm.stats?.totalContainers, 10)
        XCTAssertEqual(vm.stats?.totalStations, 3)
    }

    func testLoadDataFailure() async {
        var service = MockKontejneryService()
        service.shouldFail = true

        let vm = AppViewModel(service: service)
        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.loadError)
        XCTAssertTrue(vm.allStations.isEmpty)
    }
}

// MARK: - BrnoMapViewModel Tests

@MainActor
final class BrnoMapViewModelTests: XCTestCase {

    func testSelectedFiltersStartEmpty() {
        let vm = BrnoMapViewModel()
        XCTAssertTrue(vm.selectedFilters.isEmpty)
    }

    func testToggleFilterAddsAndRemoves() {
        let vm = BrnoMapViewModel()

        vm.selectedFilters.insert(.papir)
        XCTAssertTrue(vm.selectedFilters.contains(.papir))

        vm.selectedFilters.remove(.papir)
        XCTAssertFalse(vm.selectedFilters.contains(.papir))
    }

    func testEffectiveFiltersIncludesNavFilter() {
        let vm = BrnoMapViewModel()
        vm.selectedFilters.insert(.sklo)
        vm.activeNavFilter = .papir

        let effective = vm.effectiveFilters
        XCTAssertTrue(effective.contains(.sklo))
        XCTAssertTrue(effective.contains(.papir))
    }

    func testEffectiveFiltersWithoutNav() {
        let vm = BrnoMapViewModel()
        vm.selectedFilters = [.plast, .bio]
        vm.activeNavFilter = nil

        XCTAssertEqual(vm.effectiveFilters, [.plast, .bio])
    }

    func testSelectStation() {
        let vm = BrnoMapViewModel()
        let station = WasteStation.mock()

        vm.selectStation(station)

        XCTAssertEqual(vm.selectedStation?.id, station.id)
        XCTAssertNil(vm.route)
    }

    func testClearStation() {
        let vm = BrnoMapViewModel()
        vm.selectedStation = WasteStation.mock()
        vm.routeDistance = "500 m"
        vm.routeTravelTime = "6 min"

        vm.clearStation()

        XCTAssertNil(vm.selectedStation)
        XCTAssertNil(vm.route)
        XCTAssertEqual(vm.routeDistance, "")
        XCTAssertEqual(vm.routeTravelTime, "")
    }

    func testStopNavigationResetsAll() {
        let vm = BrnoMapViewModel()
        vm.selectedStation = WasteStation.mock()
        vm.isNavigating = true
        vm.activeNavFilter = .papir
        vm.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.6)

        vm.stopNavigation()

        XCTAssertNil(vm.selectedStation)
        XCTAssertNil(vm.route)
        XCTAssertFalse(vm.isNavigating)
        XCTAssertNil(vm.activeNavFilter)
        XCTAssertNil(vm.activeSearchPoint)
    }

    func testClearSearchPoint() {
        let vm = BrnoMapViewModel()
        vm.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.6)

        vm.clearSearchPoint()

        XCTAssertNil(vm.activeSearchPoint)
    }

    // clearStation() must also reset isNavigating and activeNavFilter
    // (these caused the "red dots" bug — stale nav pins remained after dismiss)
    func testClearStation_resetsNavigationState() {
        let vm = BrnoMapViewModel()
        vm.isNavigating = true
        vm.activeNavFilter = .sklo
        vm.activeSearchPoint = CLLocationCoordinate2D(latitude: 49.2, longitude: 16.6)

        vm.clearStation()

        XCTAssertFalse(vm.isNavigating)
        XCTAssertNil(vm.activeNavFilter)
        XCTAssertNil(vm.activeSearchPoint)
    }

    // selectStation() must clear routeTravelTime from a previous route
    // so the detail sheet doesn't briefly show stale "5 min" when tapping a new pin
    func testSelectStation_clearsTravelTime() {
        let vm = BrnoMapViewModel()
        vm.routeTravelTime = "5 min"
        vm.routeDistance = "800 m"

        vm.selectStation(WasteStation.mock())

        XCTAssertEqual(vm.routeTravelTime, "")
        XCTAssertEqual(vm.routeDistance, "")
    }

    // stopNavigation() must reset ALL state including isNavigating
    func testStopNavigation_resetsIsNavigating() {
        let vm = BrnoMapViewModel()
        vm.isNavigating = true
        vm.activeNavFilter = .bio
        vm.routeTravelTime = "3 min"

        vm.stopNavigation()

        XCTAssertFalse(vm.isNavigating)
        XCTAssertNil(vm.activeNavFilter)
        XCTAssertEqual(vm.routeTravelTime, "")
    }

    // setAllStations + filter pipeline: after setting stations and a filter,
    // visibleStations should be populated (debounced 100ms)
    func testSetAllStations_populatesVisibleStations() async throws {
        let vm = BrnoMapViewModel()
        let stations = [
            WasteStation.mock(id: "1", komodity: ["Papír"]),
            WasteStation.mock(id: "2", komodity: ["Sklo"]),
            WasteStation.mock(id: "3", komodity: ["Papír", "Plast"])
        ]

        vm.selectedFilters = [.papir]
        vm.setAllStations(stations)

        // Wait for debounce (100ms) + background task
        try await Task.sleep(nanoseconds: 400_000_000)

        // Only stations with papír should be visible
        XCTAssertTrue(vm.visibleStations.allSatisfy { $0.matches(.papir) })
        XCTAssertFalse(vm.visibleStations.contains { $0.id == "2" }) // sklo only — should not appear
    }

    // With no filters selected, visibleStations should be empty
    func testNoFilters_visibleStationsIsEmpty() async throws {
        let vm = BrnoMapViewModel()
        vm.selectedFilters = []
        vm.setAllStations([WasteStation.mock(), WasteStation.mock()])

        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertTrue(vm.visibleStations.isEmpty)
    }

    // effectiveFilters with no nav filter and no selected filters = empty
    func testEffectiveFilters_empty_whenNoFiltersSelected() {
        let vm = BrnoMapViewModel()
        vm.selectedFilters = []
        vm.activeNavFilter = nil

        XCTAssertTrue(vm.effectiveFilters.isEmpty)
    }

    // startQuickNavigation should find the nearest station with the given filter
    func testStartQuickNavigation_setsSelectedStation() {
        let vm = BrnoMapViewModel()

        // Station A — far from Brno centre
        let far = WasteStation.mock(id: "far", komodity: ["Papír"], lat: 49.30, lon: 16.60)
        // Station B — close to Brno centre
        let near = WasteStation.mock(id: "near", komodity: ["Papír"], lat: 49.195, lon: 16.607)

        let userLocation = CLLocation(latitude: 49.1951, longitude: 16.6068)
        vm.startQuickNavigation(for: .papir, in: [far, near], userLocation: userLocation)

        XCTAssertEqual(vm.selectedStation?.id, "near")
        XCTAssertTrue(vm.isNavigating)
        XCTAssertEqual(vm.activeNavFilter, .papir)
    }

    // startQuickNavigation with no matching stations — should not crash or change state
    func testStartQuickNavigation_noMatchingStations_doesNothing() {
        let vm = BrnoMapViewModel()
        let stations = [WasteStation.mock(komodity: ["Sklo"])]
        let userLocation = CLLocation(latitude: 49.1951, longitude: 16.6068)

        vm.startQuickNavigation(for: .papir, in: stations, userLocation: userLocation)

        XCTAssertNil(vm.selectedStation)
        XCTAssertFalse(vm.isNavigating)
        XCTAssertNil(vm.activeNavFilter)
    }
}

// MARK: - WasteFilter Tests

final class WasteFilterTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(WasteFilter.allCases.count, 5)
    }

    func testDisplayNameMatchesRawValue() {
        for filter in WasteFilter.allCases {
            XCTAssertEqual(filter.displayName, filter.rawValue)
        }
    }

    func testEachFilterHasIcon() {
        for filter in WasteFilter.allCases {
            XCTAssertFalse(filter.iconName.isEmpty)
        }
    }

    func testEachFilterHasUniqueColor() {
        let colors = WasteFilter.allCases.map { "\($0.color)" }
        XCTAssertEqual(colors.count, Set(colors).count, "Each filter should have a unique color")
    }
}

// MARK: - WasteStatistics Tests

final class WasteStatisticsTests: XCTestCase {

    func testEquality() {
        let a = WasteStatistics(totalContainers: 100, totalStations: 20, byKind: [.papir: 50, .sklo: 50])
        let b = WasteStatistics(totalContainers: 100, totalStations: 20, byKind: [.papir: 50, .sklo: 50])
        XCTAssertEqual(a, b)
    }

    func testInequality() {
        let a = WasteStatistics(totalContainers: 100, totalStations: 20, byKind: [.papir: 50])
        let b = WasteStatistics(totalContainers: 200, totalStations: 20, byKind: [.papir: 50])
        XCTAssertNotEqual(a, b)
    }
}
, nazev: <#String#>, nazev: <#String#>, nazev: <#String#>
