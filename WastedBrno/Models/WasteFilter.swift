//
//  WasteFilter.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import SwiftUI

// MARK: - Waste Category Filter
// Used in the filter bar and map pins to let the user show/hide specific waste types.
// Each case corresponds to a WasteKind and carries its own UI properties (color, icon, label).

enum WasteFilter: String, CaseIterable, Identifiable {
    case papir  = "Papír"
    case plast  = "Plast"
    case bio    = "Bio"
    case sklo   = "Sklo"
    case textil = "Textil"

    var id: String { rawValue }

    /// Localized display name shown in filter chips and labels.
    var displayName: String { rawValue }

    // MARK: - Mapping to WasteKind

    /// Links this UI filter to the corresponding domain model.
    /// Keeps the two enums in sync — if you add a new WasteKind, add a filter here too.
    var wasteKind: WasteKind {
        switch self {
        case .papir:  return .papir
        case .plast:  return .plast
        case .bio:    return .bioodpad
        case .sklo:   return .sklo
        case .textil: return .textil
        }
    }

    /// Lowercase keyword used to match against station komodity strings.
    /// e.g. "papír" matches "Papír a kartón", "bio" matches "Bio odpad".
    var matchKey: String {
        switch self {
        case .papir:  return "pap"
        case .plast:  return "plast"
        case .bio:    return "bio"
        case .sklo:   return "sklo"
        case .textil: return "textil"
        }
    }

    // MARK: - UI Properties

    /// Color for filter chips, map pins, and badges.
    /// Single source of truth — delegates to WasteKind.color (from WasteKindData.json).
    var color: Color {
        wasteKind.color
    }

    /// SF Symbol name for the waste type icon.
    var iconName: String {
        switch self {
        case .papir:  return "doc.text"
        case .plast:  return "trash.fill"
        case .bio:    return "leaf"
        case .sklo:   return "wineglass"
        case .textil: return "tshirt"
        }
    }
}
