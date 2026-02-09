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
    let cp: String?
    let komodity: [String]
    let coordinate: CLLocationCoordinate2D
}

enum KomoditaFilter: String, CaseIterable, Identifiable {
    case papir = "Papír"
    case plast = "Plast" // Zjednodušeno pro porovnávání
    case bio = "Bio"
    case sklo = "Sklo"  // Sjednoceno
    case textil = "Textil"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .papir: return .blue
        case .plast: return .yellow
        case .bio: return .brown
        case .sklo: return .green // Pokud ho chceš modré jako na screenshotu
        case .textil: return .purple
        }
    }
    
    var displayName: String {
        switch self {
        case .papir: return "Papír"
        case .plast: return "Plast"
        case .bio: return "Bio"
        case .sklo: return "Sklo"
        case .textil: return "Textil"
        }
    }
    
    var iconName: String {
        switch self {
        case .papir: return "doc.text"
        case .plast: return "trash.fill"
        case .bio: return "leaf"
        case .sklo: return "wineglass"
        case .textil: return "tshirt"
        }
    }
}

extension KontejnerStation {
    // Upravená funkce matches, aby stačila částečná shoda (např. "Sklo" najde "Sklo bílé")
    func matches(_ filter: KomoditaFilter) -> Bool {
        komodity.contains { $0.lowercased().contains(filter.rawValue.lowercased()) }
    }

    func dominantFilter() -> KomoditaFilter? {
        for f in KomoditaFilter.allCases {
            if matches(f) { return f }
        }
        return nil
    }
}
