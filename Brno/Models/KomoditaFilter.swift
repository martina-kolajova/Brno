//
//  KomoditaFilter.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import SwiftUI
import CoreLocation

struct KontejnerStation: Identifiable {
    let id: String
    let title: String
    let ulice: String
    let komodity: [String]
    let coordinate: CLLocationCoordinate2D
}


enum KomoditaFilter: String, CaseIterable, Identifiable {
    case papir = "Papír"
    case plast = "Plasty, nápojové kartony a hliníkové plechovky od nápojů"
    case bio = "Biologický odpad"
    case skloBarevne = "Sklo barevné"
    case skloBile = "Sklo bílé"
    case textil = "Textil"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .papir: return .blue
        case .plast: return .yellow
        case .bio: return .brown
        case .skloBarevne: return .green
        case .skloBile: return .teal
        case .textil: return .purple
        }
    }
}

extension KontejnerStation {
    func matches(_ filter: KomoditaFilter) -> Bool {
        komodity.contains(filter.rawValue)
    }

    func dominantFilter() -> KomoditaFilter? {
        for f in KomoditaFilter.allCases {
            if matches(f) { return f }
        }
        return nil
    }

    func matchesStreet(_ query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return ulice.lowercased().contains(query.lowercased())
    }
}
