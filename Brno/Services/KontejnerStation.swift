//
//  KontejnerStation.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import Foundation
import CoreLocation

protocol KontejneryServicing {
    func fetchStations(limit: Int) async throws -> [KontejnerStation]
}

final class KontejneryService: KontejneryServicing {

    private let url: URL

    init(url: URL = URL(string:
        "https://services6.arcgis.com/fUWVlHWZNxUvTUh8/arcgis/rest/services/kontejnery_separovany/FeatureServer/0/query" +
        "?where=1%3D1" +
        "&outFields=stanoviste_ogc_fid,nazev,komodita_odpad_separovany,ulice,cp" +
        "&returnGeometry=true" +
        "&outSR=4326" +
        "&f=geojson"
    )!) {
        self.url = url
    }

    func fetchStations(limit: Int = 2000) async throws -> [KontejnerStation] {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NSError(domain: "KontejneryService", code: http.statusCode)
        }

        let geo = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data)

        struct Acc {
            var title: String
            var ulice: String
            var komodity: Set<String>
            var coordinate: CLLocationCoordinate2D
        }

        var grouped: [String: Acc] = [:]

        for f in geo.features {
            guard let sid = f.properties.stanovisteOGCFID else { continue }
            guard let (lon, lat) = f.geometry.pointLonLat else { continue }

            let ulice = f.properties.ulice?.trimmedNonEmpty ?? "—"
            let cp = f.properties.cp?.trimmedNonEmpty ?? "—"
            let nazev = f.properties.nazev?.trimmedNonEmpty
            let fallbackTitle = "\(ulice) \(cp)"
            let title = nazev ?? fallbackTitle

            let kom = f.properties.komodita?.trimmedNonEmpty

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            if grouped[sid] == nil {
                var set = Set<String>()
                if let kom { set.insert(kom) }
                grouped[sid] = Acc(title: title, ulice: ulice, komodity: set, coordinate: coord)
            } else {
                if let kom { grouped[sid]?.komodity.insert(kom) }
            }
        }

        return grouped
            .prefix(max(0, limit))
            .map { (sid, acc) in
                KontejnerStation(
                    id: sid,
                    title: acc.title,
                    ulice: acc.ulice,
                    komodity: acc.komodity.sorted(),
                    coordinate: acc.coordinate
                )
            }
    }
}

// MARK: - Decodable GeoJSON (minimum)

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

    // GeoJSON Point: [lon, lat]
    var pointLonLat: (Double, Double)? {
        guard type.lowercased() == "point",
              let coordinates, coordinates.count >= 2 else { return nil }
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

    private static func decodeStringOrNumber(
        for key: CodingKeys,
        in c: KeyedDecodingContainer<CodingKeys>
    ) -> String? {
        if let s = try? c.decodeIfPresent(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return String(i) }
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) {
            if d.rounded() == d { return String(Int(d)) }
            return String(d)
        }
        return nil
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
