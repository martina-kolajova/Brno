import Foundation
import CoreLocation
import os

// MARK: - Service Protocol
// Defines what any data-fetching service must provide.
// Using a protocol allows us to swap in a MockKontejneryService during unit tests
// without changing any ViewModel code (dependency injection).

protocol KontejneryServicing {
    /// Fetches all waste container data and returns aggregated statistics + grouped stations.
    func fetchAllData() async throws -> (stats: WasteStatistics, stations: [WasteStation])
}

// MARK: - API Service
// The real implementation that talks to Brno's open data ArcGIS REST API.
// Handles: pagination, concurrent fetching, retry with exponential backoff,
// GeoJSON parsing, and single-pass grouping of containers into stations.

final class KontejneryService: KontejneryServicing {

    /// Base URL for the ArcGIS feature service — all queries are built from this.
    private let baseEndpoint = "https://services6.arcgis.com/fUWVlHWZNxUvTUh8/arcgis/rest/services/kontejnery_separovany/FeatureServer/0/query"

    /// Maximum number of features the API returns per request (ArcGIS default limit).
    private let pageSize = 1000

    /// How many times to retry a failed page request before giving up.
    private let maxRetries = 3

    /// Logger for debugging network requests and data parsing.
    /// Uses Apple's os.Logger — lightweight, zero cost when not observed.
    private let logger = Logger(subsystem: "com.WastedBrno", category: "KontejneryService")

    /// URLSession with a 15s timeout so requests don't hang forever.
    /// A custom session can be injected for testing (e.g. using MockURLProtocol).
    private let session: URLSession

    /// Initialiser with optional session injection.
    /// - Production: creates a session with 15s request / 60s resource timeouts.
    /// - Testing: pass a session configured with MockURLProtocol to intercept requests.
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Main Entry Point

    /// Fetches ALL container data using paginated requests, then computes stats + grouped stations.
    /// This is the only public method — ViewModels call this and get back everything they need.
    ///
    /// Flow:
    ///   1. Fetch total count (lightweight request, no geometry)
    ///   2. Fetch all pages concurrently using TaskGroup
    ///   3. Build result in a single pass (count + group + deduplicate)
    func fetchAllData() async throws -> (stats: WasteStatistics, stations: [WasteStation]) {

        // Step 1: Get total count of containers (tiny request, no geometry downloaded)
        let total = try await fetchTotalCount()
        logger.info("📦 Total containers from API: \(total)")

        // Edge case: API returned 0 containers — return empty result immediately
        guard total > 0 else {
            logger.warning("⚠️ API returned 0 containers")
            return (WasteStatistics(totalContainers: 0, totalStations: 0, byKind: [:]), [])
        }

        // Step 2: Calculate number of pages and fetch them all concurrently
        // e.g. 2500 containers / 1000 per page = 3 pages fetched in parallel
        let pageCount = Int(ceil(Double(total) / Double(pageSize)))
        logger.info("📄 Fetching \(pageCount) pages (pageSize: \(self.pageSize))")
        var allFeatures: [GeoJSONFeature] = []
        allFeatures.reserveCapacity(total)  // pre-allocate to avoid repeated reallocations

        // TaskGroup runs all page fetches concurrently — much faster than sequential
        try await withThrowingTaskGroup(of: [GeoJSONFeature].self) { group in
            for page in 0..<pageCount {
                let offset = page * pageSize
                group.addTask { [self] in
                    try await self.fetchPage(offset: offset)
                }
            }
            // Collect results as each page completes (order doesn't matter)
            for try await features in group {
                allFeatures.append(contentsOf: features)
            }
        }

        // Step 3: Build the final result from all features in a single O(n) pass
        let result = buildResult(from: allFeatures)
        logger.info("✅ Loaded \(result.stations.count) stations, \(result.stats.totalContainers) containers")
        return result
    }

    // MARK: - Private API Calls

    /// Returns the total number of features without downloading any actual data.
    /// Uses `returnCountOnly=true` — the response is just `{ "count": 2547 }`.
    private func fetchTotalCount() async throws -> Int {
        var components = URLComponents(string: baseEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "where", value: "1=1"),           // all records
            URLQueryItem(name: "returnCountOnly", value: "true"), // just the count
            URLQueryItem(name: "f", value: "json")               // JSON format
        ]
        let (data, response) = try await session.data(from: components.url!)
        try validateResponse(response)

        struct CountResponse: Decodable { let count: Int }
        return try JSONDecoder().decode(CountResponse.self, from: data).count
    }

    /// Fetches a single page of GeoJSON features with retry logic.
    /// Each page contains up to `pageSize` (1000) container records.
    /// On failure, retries up to `maxRetries` times with exponential backoff (1s → 2s → 4s).
    private func fetchPage(offset: Int) async throws -> [GeoJSONFeature] {
        var components = URLComponents(string: baseEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "where", value: "1=1"),
            URLQueryItem(name: "outFields", value: "stanoviste_ogc_fid,nazev,komodita_odpad_separovany,ulice,cp"),
            URLQueryItem(name: "returnGeometry", value: "true"),  // include GPS coordinates
            URLQueryItem(name: "outSR", value: "4326"),           // WGS84 (standard lat/lon)
            URLQueryItem(name: "f", value: "geojson"),            // GeoJSON format
            URLQueryItem(name: "resultRecordCount", value: "\(pageSize)"),
            URLQueryItem(name: "resultOffset", value: "\(offset)") // pagination offset
        ]

        var lastError: Error?
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await session.data(from: components.url!)
                try validateResponse(response)
                return try JSONDecoder().decode(GeoJSONResponse.self, from: data).features
            } catch {
                lastError = error
                logger.warning("⚠️ Page offset \(offset) attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < maxRetries {
                    // Exponential backoff: attempt 1 → 1s, attempt 2 → 2s, attempt 3 → 4s
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000)
                }
            }
        }
        logger.error("❌ Page offset \(offset) failed after \(self.maxRetries) retries")
        throw lastError ?? ServiceError.httpError(statusCode: -1)
    }

    /// Validates that the HTTP response has a 2xx status code.
    /// Throws ServiceError.httpError if not — this is caught by the retry logic above.
    private func validateResponse(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }
    }
}

// MARK: - Result Builder (single-pass parsing)
// Transforms raw GeoJSON features into app models in one loop.
// Does three things simultaneously:
//   1. Counts containers per waste kind (for WasteStatistics)
//   2. Groups containers into stations by stanoviste_ogc_fid
//   3. Deduplicates komodity per station using Set<String>

private extension KontejneryService {

    /// Groups containers into stations using stanoviste_ogc_fid (the official dataset key).
    /// Returns both aggregated statistics and a list of unique stations.
    func buildResult(from features: [GeoJSONFeature]) -> (stats: WasteStatistics, stations: [WasteStation]) {

        /// Counts per waste kind — e.g. [.papir: 320, .sklo: 180, ...]
        var byKind: [WasteKind: Int] = [:]

        /// Tracks unique station IDs to count total stations
        var stationIDs = Set<String>()

        /// Temporary accumulator for grouping containers into stations
        struct GroupAccumulator {
            var nazev: String                        // station name
            var komodity: Set<String>                // unique waste types (deduplicated)
            var coordinate: CLLocationCoordinate2D   // GPS position
        }

        /// Dictionary keyed by station ID — each entry collects all containers at that location
        var grouped: [String: GroupAccumulator] = [:]

        // Single pass through all features — O(n) complexity
        for feature in features {
            let props = feature.properties

            // Track unique station IDs for the total station count
            if let sid = props.stanovisteOGCFID {
                stationIDs.insert(sid)
            }

            // Classify the waste type using substring matching
            // e.g. "Papír a kartón" contains "pap" → counted as .papir
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
            // Multiple containers at the same location share one station ID
            guard let sid = props.stanovisteOGCFID,
                  let (lon, lat) = feature.geometry.pointCoordinates else { continue }

            let nazev = props.nazev?.trimmedOrNil ?? "—"
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            if grouped[sid] == nil {
                // First container at this station — create a new accumulator
                var kinds = Set<String>()
                if let k = props.komodita?.trimmedOrNil { kinds.insert(k) }
                grouped[sid] = GroupAccumulator(nazev: nazev, komodity: kinds, coordinate: coord)
            } else if let k = props.komodita?.trimmedOrNil {
                // Additional container at an existing station — just add the waste type
                grouped[sid]?.komodity.insert(k)
            }
        }

        // Build the final statistics model
        let stats = WasteStatistics(
            totalContainers: features.count,
            totalStations: stationIDs.count,
            byKind: byKind
        )

        // Convert grouped accumulators into WasteStation models for the map
        let stations = grouped.map { (sid, acc) in
            WasteStation(
                id: sid,
                nazev: acc.nazev,
                komodity: acc.komodity.sorted(),  // sorted for consistent display order
                coordinate: acc.coordinate
            )
        }

        return (stats, stations)
    }
}

// MARK: - Error
// Custom error type for HTTP failures.
// Conforms to LocalizedError so the error message is human-readable.

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
// Private structs that map to the ArcGIS GeoJSON response format.
// Only used inside this file — the rest of the app works with WasteStation and WasteStatistics.

/// Top-level GeoJSON response containing an array of features.
private struct GeoJSONResponse: Decodable {
    let features: [GeoJSONFeature]
}

/// A single GeoJSON feature = one container record with geometry (GPS) and properties (metadata).
private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
    let properties: GeoJSONProperties
}

/// GeoJSON geometry — we only care about Point type (lat/lon of the container).
private struct GeoJSONGeometry: Decodable {
    let type: String           // "Point" for container locations
    let coordinates: [Double]? // [longitude, latitude] — note: GeoJSON uses lon,lat order

    /// Returns (longitude, latitude) for Point geometries.
    /// Returns nil for non-Point types or malformed data.
    var pointCoordinates: (Double, Double)? {
        guard type.lowercased() == "point",
              let coordinates, coordinates.count >= 2 else { return nil }
        return (coordinates[0], coordinates[1])  // (lon, lat)
    }
}

/// Container metadata from the API.
/// Fields match the ArcGIS feature service column names.
private struct GeoJSONProperties: Decodable {
    let stanovisteOGCFID: String?  // unique station ID (groups multiple containers at one location)
    let nazev: String?             // station name / description
    let komodita: String?          // waste type string (e.g. "Papír", "Sklo barevné")
    let ulice: String?             // street name
    let cp: String?                // house number

    /// Maps Swift property names to the API's JSON field names.
    enum CodingKeys: String, CodingKey {
        case stanovisteOGCFID = "stanoviste_ogc_fid"
        case nazev
        case komodita = "komodita_odpad_separovany"
        case ulice
        case cp
    }

    /// Custom decoder — needed because stanovisteOGCFID and cp may arrive as String OR Int
    /// depending on the API version. decodeFlexibleString handles both cases.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stanovisteOGCFID = Self.decodeFlexibleString(for: .stanovisteOGCFID, in: container)
        cp = Self.decodeFlexibleString(for: .cp, in: container)
        nazev = try container.decodeIfPresent(String.self, forKey: .nazev)
        komodita = try container.decodeIfPresent(String.self, forKey: .komodita)
        ulice = try container.decodeIfPresent(String.self, forKey: .ulice)
    }

    /// Handles API fields that may arrive as String or Int.
    /// Tries String first, then Int (converted to String). Returns nil if neither works.
    /// This defensive approach prevents crashes when the API changes field types.
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
    /// Used to normalise API strings — treats whitespace-only values as missing.
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
