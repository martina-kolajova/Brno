import XCTest
import CoreLocation
@testable import WastedBrno

// MARK: - Mock API Service
// Redefine here so KontejneryServiceTests is self-contained and does not depend on WastedBrnoTests.swift

private struct MockKontejneryService: KontejneryServicing {
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

// MARK: - WasteStation test helper

private extension WasteStation {
    static func mock(
        id: String = "1",
        nazev: String = "Test Station",
        komodity: [String] = ["Papír", "Plast"],
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

// MARK: - Mock URL Protocol
// Intercepts every URLSession request and returns whatever we configure.
// This lets us test the real KontejneryService without any network connection.

final class MockURLProtocol: URLProtocol {

    // Closure that the test sets up — returns (Data, HTTPURLResponse) or throws
    static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    // Tell URLSession that this protocol can handle every request
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private extension KontejneryServiceTests {

    // Builds a minimal GeoJSON FeatureCollection with one Point feature.
    // Parameters match the real API field names so JSONDecoder handles them correctly.
    func makeGeoJSON(
        stationID: String = "1",
        komodita: String = "Papír",
        nazev: String = "Test Station",
        lat: Double = 49.1951,
        lon: Double = 16.6068
    ) -> Data {
        let json = """
        {
            "features": [
                {
                    "geometry": {
                        "type": "Point",
                        "coordinates": [\(lon), \(lat)]
                    },
                    "properties": {
                        "stanoviste_ogc_fid": "\(stationID)",
                        "nazev": "\(nazev)",
                        "komodita_odpad_separovany": "\(komodita)",
                        "ulice": "Testovací",
                        "cp": "42"
                    }
                }
            ]
        }
        """
        return Data(json.utf8)
    }

    // Builds the tiny count response the real API returns first.
    func makeCountJSON(count: Int) -> Data {
        Data("{\"count\":\(count)}".utf8)
    }

    // Creates a 200 OK HTTPURLResponse for the given URL string.
    func ok(for urlString: String) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: urlString)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    // Creates an error HTTPURLResponse with the given status code.
    func errorResponse(statusCode: Int, for urlString: String) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: urlString)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

// MARK: - KontejneryService Tests

final class KontejneryServiceTests: XCTestCase {

    // The real service wired to a mock URLSession — no real network calls
    var sut: KontejneryService!
    var mockSession: URLSession!

    override func setUp() {
        super.setUp()
        // Register MockURLProtocol so URLSession uses it instead of the real network
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        sut = KontejneryService(session: mockSession)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        sut = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - ServiceError

    // Verify that ServiceError carries the correct status code in its description
    func testServiceErrorDescription_containsStatusCode() {
        let error = ServiceError.httpError(statusCode: 404)
        XCTAssertTrue(
            error.errorDescription?.contains("404") ?? false,
            "Error description should mention the HTTP status code"
        )
    }

    func testServiceErrorDescription_500() {
        let error = ServiceError.httpError(statusCode: 500)
        XCTAssertTrue(error.errorDescription?.contains("500") ?? false)
    }

    // MARK: - MockKontejneryService (protocol conformance)
    // Ensures the mock used in AppViewModel tests behaves correctly

    func testMockService_returnsConfiguredResult() async throws {
        // Arrange — set up a mock with known data
        let expectedStats = WasteStatistics(totalContainers: 5, totalStations: 2, byKind: [.papir: 3, .sklo: 2])
        let expectedStations = [WasteStation.mock(id: "A"), WasteStation.mock(id: "B")]
        let mock = MockKontejneryService(result: (expectedStats, expectedStations))

        // Act
        let result = try await mock.fetchAllData()

        // Assert
        XCTAssertEqual(result.stats.totalContainers, 5)
        XCTAssertEqual(result.stats.totalStations, 2)
        XCTAssertEqual(result.stations.count, 2)
        XCTAssertEqual(result.stations.first?.id, "A")
    }

    func testMockService_throwsWhenShouldFail() async {
        // Arrange — configure mock to simulate a server error
        var mock = MockKontejneryService()
        mock.shouldFail = true

        // Act & Assert — fetchAllData must throw
        do {
            _ = try await mock.fetchAllData()
            XCTFail("Expected an error to be thrown")
        } catch let error as ServiceError {
            // Verify it's the correct HTTP 500 error
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected httpError(statusCode: 500)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockService_defaultResultIsEmpty() async throws {
        // A freshly created MockKontejneryService should return empty data
        let mock = MockKontejneryService()
        let result = try await mock.fetchAllData()

        XCTAssertEqual(result.stats.totalContainers, 0)
        XCTAssertEqual(result.stats.totalStations, 0)
        XCTAssertTrue(result.stations.isEmpty)
    }

    // MARK: - HTTP 200 — happy path

    func testFetchAllData_successfulResponse_returnsOneStation() async throws {
        // Arrange — first request = count, second = page data
        var callCount = 0
        MockURLProtocol.requestHandler = { [self] request in
            callCount += 1
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") {
                // Count request → tell the service there is exactly 1 container
                return (makeCountJSON(count: 1), ok(for: url))
            } else {
                // Page request → return one GeoJSON feature
                return (makeGeoJSON(), ok(for: url))
            }
        }

        // Act
        let result = try await sut.fetchAllData()

        // Assert
        XCTAssertEqual(result.stats.totalContainers, 1, "Should have parsed 1 container")
        XCTAssertEqual(result.stations.count, 1,         "Should have grouped into 1 station")
        XCTAssertEqual(result.stats.byKind[.papir], 1,   "Papír count should be 1")
    }

    func testFetchAllData_multipleKomodity_groupedUnderOneStation() async throws {
        // Two features with the same stanoviste_ogc_fid but different komodita
        // → should produce 1 station with 2 komodity entries
        let json = """
        {
            "features": [
                {
                    "geometry": { "type": "Point", "coordinates": [16.6068, 49.1951] },
                    "properties": {
                        "stanoviste_ogc_fid": "99",
                        "nazev": "Grouped Station",
                        "komodita_odpad_separovany": "Papír",
                        "ulice": "Testovací", "cp": "1"
                    }
                },
                {
                    "geometry": { "type": "Point", "coordinates": [16.6068, 49.1951] },
                    "properties": {
                        "stanoviste_ogc_fid": "99",
                        "nazev": "Grouped Station",
                        "komodita_odpad_separovany": "Sklo",
                        "ulice": "Testovací", "cp": "1"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") {
                return (makeCountJSON(count: 2), ok(for: url))
            }
            return (json, ok(for: url))
        }

        let result = try await sut.fetchAllData()

        // Both features share the same station ID → must collapse into 1 station
        XCTAssertEqual(result.stations.count, 1, "Two features with same ID should merge into 1 station")
        XCTAssertEqual(result.stats.totalContainers, 2)
        // The merged station should have both komodity
        let komodity = result.stations.first?.komodity ?? []
        XCTAssertTrue(komodity.contains { $0.lowercased().contains("pap") }, "Should have Papír")
        XCTAssertTrue(komodity.contains { $0.lowercased().contains("sklo") }, "Should have Sklo")
    }

    // MARK: - HTTP error responses

    func testFetchAllData_countRequest_404_throwsHTTPError() async {
        // Arrange — count endpoint returns 404
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            return (Data(), errorResponse(statusCode: 404, for: url))
        }

        // Act & Assert
        do {
            _ = try await sut.fetchAllData()
            XCTFail("Should have thrown for HTTP 404")
        } catch let error as ServiceError {
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 404, "Should surface the 404 status code")
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchAllData_pageRequest_500_throwsHTTPError() async {
        // Count succeeds, but the page request returns 500
        // The service retries 3 times then throws — so we allow up to 4 calls total
        var pageCallCount = 0
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") {
                return (makeCountJSON(count: 1), ok(for: url))
            }
            pageCallCount += 1
            return (Data(), errorResponse(statusCode: 500, for: url))
        }

        do {
            _ = try await sut.fetchAllData()
            XCTFail("Should have thrown after exhausting retries")
        } catch let error as ServiceError {
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Service retries 3 times (maxRetries = 3)
        XCTAssertEqual(pageCallCount, 3, "Should have retried exactly 3 times before giving up")
    }

    // MARK: - Zero containers edge case

    func testFetchAllData_zeroContainers_returnsEmptyResult() async throws {
        // API reports 0 containers — service should return empty without making page requests
        var pageRequested = false
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") {
                return (makeCountJSON(count: 0), ok(for: url))
            }
            pageRequested = true
            return (makeGeoJSON(), ok(for: url))
        }

        let result = try await sut.fetchAllData()

        XCTAssertEqual(result.stats.totalContainers, 0)
        XCTAssertTrue(result.stations.isEmpty)
        XCTAssertFalse(pageRequested, "No page requests should be made when count is 0")
    }

    // MARK: - Waste kind classification

    func testFetchAllData_clasifiesPlastCorrectly() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") { return (makeCountJSON(count: 1), ok(for: url)) }
            return (makeGeoJSON(komodita: "Plast a karton"), ok(for: url))
        }

        let result = try await sut.fetchAllData()
        XCTAssertEqual(result.stats.byKind[.plast], 1, "Plast a karton should be classified as .plast")
        XCTAssertNil(result.stats.byKind[.papir])
    }

    func testFetchAllData_clasifiesSkloCorrently() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") { return (makeCountJSON(count: 1), ok(for: url)) }
            return (makeGeoJSON(komodita: "Sklo barevné"), ok(for: url))
        }

        let result = try await sut.fetchAllData()
        XCTAssertEqual(result.stats.byKind[.sklo], 1, "Sklo barevné should be classified as .sklo")
    }

    func testFetchAllData_clasifiesBioCorrectly() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") { return (makeCountJSON(count: 1), ok(for: url)) }
            return (makeGeoJSON(komodita: "Bioodpad"), ok(for: url))
        }

        let result = try await sut.fetchAllData()
        XCTAssertEqual(result.stats.byKind[.bioodpad], 1, "Bioodpad should be classified as .bioodpad")
    }

    func testFetchAllData_clasifiesTextilCorrectly() async throws {
        MockURLProtocol.requestHandler = { [self] request in
            let url = request.url!.absoluteString
            if url.contains("returnCountOnly") { return (makeCountJSON(count: 1), ok(for: url)) }
            return (makeGeoJSON(komodita: "Textil"), ok(for: url))
        }

        let result = try await sut.fetchAllData()
        XCTAssertEqual(result.stats.byKind[.textil], 1, "Textil should be classified as .textil")
    }
}
