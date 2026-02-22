import Foundation
import CoreLocation

// MARK: - Service Protocol

protocol KontejneryServicing {
    func fetchAllData() async throws -> (stats: KontejnerStats, stations: [KontejnerStation])
}

// MARK: - API Service

final class KontejneryService: KontejneryServicing {

    private let baseURL: URL

    init(baseURL: URL = URL(string:
        "https://services6.arcgis.com/fUWVlHWZNxUvTUh8/arcgis/rest/services/kontejnery_separovany/FeatureServer/0/query"
        + "?where=1%3D1"
        + "&outFields=stanoviste_ogc_fid,nazev,komodita_odpad_separovany,ulice,cp"
        + "&returnGeometry=true"
        + "&outSR=4326"
        + "&f=geojson"
        + "&resultType=standard"
        + "&resultRecordCount=1000"
    )!) {
        self.baseURL = baseURL
    }

    /// Fetches all container data and computes stats + grouped stations in a single pass.
    func fetchAllData() async throws -> (stats: KontejnerStats, stations: [KontejnerStation]) {
        let (data, response) = try await URLSession.shared.data(from: baseURL)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }

        let collection = try JSONDecoder().decode(GeoJSONResponse.self, from: data)
        return buildResult(from: collection.features)
    }
}

// MARK: - Result Builder (single-pass parsing)

private extension KontejneryService {

    func buildResult(from features: [GeoJSONFeature]) -> (stats: KontejnerStats, stations: [KontejnerStation]) {
        var byKind: [WasteKind: Int] = [:]
        var stationIDs = Set<String>()

        struct GroupAccumulator {
            var title: String
            var ulice: String
            var cp: String?
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

            // Group features into stations
            guard let sid = props.stanovisteOGCFID,
                  let (lon, lat) = feature.geometry.pointCoordinates else { continue }

            let ulice = props.ulice?.trimmedOrNil ?? "—"
            let cp = props.cp?.trimmedOrNil
            let title = props.nazev?.trimmedOrNil ?? "\(ulice) \(cp ?? "")"
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            if grouped[sid] == nil {
                var kinds = Set<String>()
                if let k = props.komodita?.trimmedOrNil { kinds.insert(k) }
                grouped[sid] = GroupAccumulator(title: title, ulice: ulice, cp: cp, komodity: kinds, coordinate: coord)
            } else if let k = props.komodita?.trimmedOrNil {
                grouped[sid]?.komodity.insert(k)
            }
        }

        let stats = KontejnerStats(
            totalContainers: features.count,
            totalStations: stationIDs.count,
            byKind: byKind
        )

        let stations = grouped.map { (sid, acc) in
            KontejnerStation(
                id: sid,
                title: acc.title,
                ulice: acc.ulice,
                cp: acc.cp,
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
