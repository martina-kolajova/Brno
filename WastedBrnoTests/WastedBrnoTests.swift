import XCTest
import CoreLocation
@testable import Brno

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
