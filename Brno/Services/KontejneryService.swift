import Foundation
import CoreLocation

// MARK: - Service Protocol

protocol KontejneryServicing {
    func fetchAllData() async throws -> (stats: WasteStatistics, stations: [WasteStation])
}

// MARK: - API Service

final class KontejneryService: KontejneryServicing {

    private let baseEndpoint = "https://services6.arcgis.com/fUWVlHWZNxUvTUh8/arcgis/rest/services/kontejnery_separovany/FeatureServer/0/query"
    private let pageSize = 1000
    private let maxRetries = 3

    /// URLSession with a 15s timeout so requests don't hang forever.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    /// Fetches ALL container data using paginated requests, then computes stats + grouped stations.
    func fetchAllData() async throws -> (stats: WasteStatistics, stations: [WasteStation]) {

        // 1. Get total count (tiny request, no geometry)
        let total = try await fetchTotalCount()
        guard total > 0 else { return (WasteStatistics(totalContainers: 0, totalStations: 0, byKind: [:]), []) }

        // 2. Fetch all pages concurrently
        let pageCount = Int(ceil(Double(total) / Double(pageSize)))
        var allFeatures: [GeoJSONFeature] = []
        allFeatures.reserveCapacity(total)

        try await withThrowingTaskGroup(of: [GeoJSONFeature].self) { group in
            for page in 0..<pageCount {
                let offset = page * pageSize
                group.addTask { [self] in
                    try await self.fetchPage(offset: offset)
                }
            }
            for try await features in group {
                allFeatures.append(contentsOf: features)
            }
        }

        // 3. Build result from all features in a single pass
        return buildResult(from: allFeatures)
    }

    // MARK: - Private API calls

    /// Returns the total number of features without downloading any data.
    private func fetchTotalCount() async throws -> Int {
        var components = URLComponents(string: baseEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "where", value: "1=1"),
            URLQueryItem(name: "returnCountOnly", value: "true"),
            URLQueryItem(name: "f", value: "json")
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validateResponse(response)

        struct CountResponse: Decodable { let count: Int }
        return try JSONDecoder().decode(CountResponse.self, from: data).count
    }

    /// Fetches a single page of features with retry logic.
    private func fetchPage(offset: Int) async throws -> [GeoJSONFeature] {
        var components = URLComponents(string: baseEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "where", value: "1=1"),
            URLQueryItem(name: "outFields", value: "stanoviste_ogc_fid,nazev,komodita_odpad_separovany,ulice,cp"),
            URLQueryItem(name: "returnGeometry", value: "true"),
            URLQueryItem(name: "outSR", value: "4326"),
            URLQueryItem(name: "f", value: "geojson"),
            URLQueryItem(name: "resultRecordCount", value: "\(pageSize)"),
            URLQueryItem(name: "resultOffset", value: "\(offset)")
        ]

        var lastError: Error?
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await session.data(from: components.url!)
                try validateResponse(response)
                return try JSONDecoder().decode(GeoJSONResponse.self, from: data).features
            } catch {
                lastError = error
                if attempt < maxRetries {
                    // Exponential backoff: 1s, 2s, 4s
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000)
                }
            }
        }
        throw lastError ?? ServiceError.httpError(statusCode: -1)
    }

    /// Validates HTTP response status code.
    private func validateResponse(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }
    }
}

// MARK: - Result Builder (single-pass parsing)

private extension KontejneryService {

    /// Groups containers into stations using stanoviste_ogc_fid (official dataset key).
    func buildResult(from features: [GeoJSONFeature]) -> (stats: WasteStatistics, stations: [WasteStation]) {
        var byKind: [WasteKind: Int] = [:]
        var stationIDs = Set<String>()

        struct GroupAccumulator {
            var nazev: String
            var komodity: Set<String>
            var coordinate: CLLocationCoordinate2D
        }

        var grouped: [String: GroupAccumulator] = [:]

        for feature in features {
            let props = feature.properties

            // Track unique station IDs
            if let sid = props.stanovisteOGCFID {
                stationIDs.insert(sid)
            }

            // Count by waste kind
            if let rawKind = props.komodita?.lowercased() {
                if rawKind.contains("pap") {
                    byKind[.papir, default: 0] += 1
                } else if rawKind.contains("plast") || rawKind.contains("karton") || rawKind.contains("plech") {
                    byKind[.plast, default: 0] += 1
                } else if rawKind.contains("sklo") {
                    byKind[.sklo, default: 0] += 1
                } else if rawKind.contains("bio") {
                    byKind[.bioodpad, default: 0] += 1
                } else if rawKind.contains("textil") {
                    byKind[.textil, default: 0] += 1
                }
            }

            // Group features into stations by stanoviste_ogc_fid
            guard let sid = props.stanovisteOGCFID,
                  let (lon, lat) = feature.geometry.pointCoordinates else { continue }

            let nazev = props.nazev?.trimmedOrNil ?? "—"
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            if grouped[sid] == nil {
                var kinds = Set<String>()
                if let k = props.komodita?.trimmedOrNil { kinds.insert(k) }
                grouped[sid] = GroupAccumulator(nazev: nazev, komodity: kinds, coordinate: coord)
            } else if let k = props.komodita?.trimmedOrNil {
                grouped[sid]?.komodity.insert(k)
            }
        }

        let stats = WasteStatistics(
            totalContainers: features.count,
            totalStations: stationIDs.count,
            byKind: byKind
        )

        let stations = grouped.map { (sid, acc) in
            WasteStation(
                id: sid,
                nazev: acc.nazev,
                komodity: acc.komodity.sorted(),
                coordinate: acc.coordinate
            )
        }
    

        return (stats, stations)
    }
}

// MARK: - Error

enum ServiceError: LocalizedError {
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "Server responded with status code \(code)"
        }
    }
}

// MARK: - GeoJSON Decodable Models

private struct GeoJSONResponse: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
    let properties: GeoJSONProperties
}

private struct GeoJSONGeometry: Decodable {
    let type: String
    let coordinates: [Double]?

    /// Returns (longitude, latitude) for Point geometries.
    var pointCoordinates: (Double, Double)? {
        guard type.lowercased() == "point",
              let coordinates, coordinates.count >= 2 else { return nil }
        return (coordinates[0], coordinates[1])
    }
}

private struct GeoJSONProperties: Decodable {
    let stanovisteOGCFID: String?
    let nazev: String?
    let komodita: String?
    let ulice: String?
    let cp: String?

    enum CodingKeys: String, CodingKey {
        case stanovisteOGCFID = "stanoviste_ogc_fid"
        case nazev
        case komodita = "komodita_odpad_separovany"
        case ulice
        case cp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stanovisteOGCFID = Self.decodeFlexibleString(for: .stanovisteOGCFID, in: container)
        cp = Self.decodeFlexibleString(for: .cp, in: container)
        nazev = try container.decodeIfPresent(String.self, forKey: .nazev)
        komodita = try container.decodeIfPresent(String.self, forKey: .komodita)
        ulice = try container.decodeIfPresent(String.self, forKey: .ulice)
    }

    /// Handles API fields that may arrive as String or Int.
    private static func decodeFlexibleString(
        for key: CodingKeys,
        in container: KeyedDecodingContainer<CodingKeys>
    ) -> String? {
        if let str = try? container.decodeIfPresent(String.self, forKey: key) {
            return str.trimmedOrNil
        }
        if let num = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(num)
        }
        return nil
    }
}

// MARK: - String Helper

private extension String {
    /// Returns the trimmed string, or nil if empty.
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
