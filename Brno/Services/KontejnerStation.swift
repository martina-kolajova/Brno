//
//  KontejnerStation.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import Foundation
import CoreLocation

// MARK: - Protocol
protocol KontejneryServicing {
    func fetchStats() async throws -> KontejnerStats
    func fetchStations(limit: Int) async throws -> [KontejnerStation]
    func fetchAllData() async throws -> (stats: KontejnerStats, stations: [KontejnerStation])
}

final class KontejneryService: KontejneryServicing {

    private let url: URL

    init(url: URL = URL(string:
        "https://services6.arcgis.com/fUWVlHWZNxUvTUh8/arcgis/rest/services/kontejnery_separovany/FeatureServer/0/query" +
        "?where=1%3D1" +
        "&outFields=stanoviste_ogc_fid,nazev,komodita_odpad_separovany,ulice,cp" +
        "&returnGeometry=true" +
        "&outSR=4326" +
        "&f=geojson" +
        "&resultType=standard" +
        "&resultRecordCount=1000"
    )!) {
        self.url = url
    }

    func fetchStats() async throws -> KontejnerStats {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NSError(domain: "KontejneryService", code: http.statusCode)
        }
        let geo = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data)

        var byKind: [WasteKind: Int] = [:]
        var stationIDs = Set<String>()

        for f in geo.features {
            if let sid = f.properties.stanovisteOGCFID { stationIDs.insert(sid) }
            if let kom = f.properties.komodita?.lowercased() {
                if kom.contains("pap") { byKind[.papir, default: 0] += 1 }
                else if kom.contains("plast") || kom.contains("karton") || kom.contains("plech") { byKind[.plast, default: 0] += 1 }
                else if kom.contains("sklo") { byKind[.sklo, default: 0] += 1 }
                else if kom.contains("bio") { byKind[.bioodpad, default: 0] += 1 }
                else if kom.contains("textil") { byKind[.textil, default: 0] += 1 }
            }
        }
        return KontejnerStats(totalContainers: geo.features.count, totalStations: stationIDs.count, byKind: byKind)
    }

    func fetchStations(limit: Int = 20000) async throws -> [KontejnerStation] {
        let result = try await fetchAllData()
        return Array(result.stations.prefix(max(0, limit)))
    }

    func fetchAllData() async throws -> (stats: KontejnerStats, stations: [KontejnerStation]) {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NSError(domain: "KontejneryService", code: http.statusCode)
        }

        let geo = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data)

        var byKind: [WasteKind: Int] = [:]
        var stationIDs = Set<String>()
        
        // Pomocná struktura pro seskupování (přidáno cp)
        struct Acc {
            var title: String
            var ulice: String
            var cp: String? // Přidáno sem
            var komodity: Set<String>
            var coordinate: CLLocationCoordinate2D
        }
        var groupedStations: [String: Acc] = [:]

        for f in geo.features {
            let properties = f.properties
            
            if let sid = properties.stanovisteOGCFID {
                stationIDs.insert(sid)
            }

            if let kom = properties.komodita?.lowercased() {
                if kom.contains("pap") {
                    byKind[.papir, default: 0] += 1
                }
                else if kom.contains("plast") || kom.contains("karton") || kom.contains("plech") {
                    byKind[.plast, default: 0] += 1
                }
                // OPRAVA: Sjednocení všech typů skla (bílé i barevné)
                else if kom.contains("sklo") {
                    byKind[.sklo, default: 0] += 1
                }
                else if kom.contains("bio") {
                    byKind[.bioodpad, default: 0] += 1
                }
                else if kom.contains("textil") {
                    byKind[.textil, default: 0] += 1
                }
            }
            guard let sid = properties.stanovisteOGCFID,
                  let (lon, lat) = f.geometry.pointLonLat else { continue }

            let ulice = properties.ulice?.trimmedNonEmpty ?? "—"
            let cpValue = properties.cp?.trimmedNonEmpty // Načtení čísla popisného
            let title = properties.nazev?.trimmedNonEmpty ?? "\(ulice) \(cpValue ?? "")"
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            if groupedStations[sid] == nil {
                var set = Set<String>()
                if let k = properties.komodita?.trimmedNonEmpty { set.insert(k) }
                groupedStations[sid] = Acc(title: title, ulice: ulice, cp: cpValue, komodity: set, coordinate: coord)
            } else if let k = properties.komodita?.trimmedNonEmpty {
                groupedStations[sid]?.komodity.insert(k)
            }
        }

        let stats = KontejnerStats(
            totalContainers: geo.features.count,
            totalStations: stationIDs.count,
            byKind: byKind
        )

        let stations = groupedStations.map { (sid, acc) in
            KontejnerStation(
                id: sid,
                title: acc.title,
                ulice: acc.ulice,
                cp: acc.cp, // Teď už se cp správně předává
                komodity: acc.komodity.sorted(),
                coordinate: acc.coordinate
            )
        }

        return (stats, stations)
    }
}

// ... (zbytek souboru s privátními strukturami zůstává stejný jako ve tvém souboru)
// MARK: - Pomocné struktury pro dekódování (soukromé)

private struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
    let properties: KontejnerProperties
}

private struct GeoJSONGeometry: Decodable {
    let type: String
    let coordinates: [Double]?
    var pointLonLat: (Double, Double)? {
        guard type.lowercased() == "point", let coordinates, coordinates.count >= 2 else { return nil }
        return (coordinates[0], coordinates[1])
    }
}

private struct KontejnerProperties: Decodable {
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
        case cp = "cp"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.stanovisteOGCFID = Self.decodeStringOrNumber(for: .stanovisteOGCFID, in: c)
        self.cp = Self.decodeStringOrNumber(for: .cp, in: c)
        self.nazev = try c.decodeIfPresent(String.self, forKey: .nazev)
        self.komodita = try c.decodeIfPresent(String.self, forKey: .komodita)
        self.ulice = try c.decodeIfPresent(String.self, forKey: .ulice)
    }

    private static func decodeStringOrNumber(for key: CodingKeys, in c: KeyedDecodingContainer<CodingKeys>) -> String? {
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return String(i) }
        return nil
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

