//
//  KomoditaFilter.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import SwiftUI

// MARK: - Waste Category Filter

enum KomoditaFilter: String, CaseIterable, Identifiable {
    case papir = "Papír"
    case plast = "Plast"
    case bio = "Bio"
    case sklo = "Sklo"
    case textil = "Textil"

    var id: String { rawValue }

    /// Same as rawValue — kept for readability in views.
    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .papir: return .blue
        case .plast: return .yellow
        case .bio: return .brown
        case .sklo: return .green
        case .textil: return .purple
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
