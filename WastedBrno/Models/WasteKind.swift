import Foundation
import SwiftUI

// MARK: - Waste Kind
// Domain model for waste categories (paper, plastic, glass, bio, textile).
// Each kind loads its display data (title, color, hint, warning, education text)
// from WasteKindData.json so we can update content without changing code.
// Used by: WasteDetailView (info sheet), WasteStatsChart (orloj), WasteStatistics.

enum WasteKind: String, CaseIterable, Hashable, Identifiable {
    case papir, plast, sklo, bioodpad, textil

    var id: String { self.rawValue }
}

// MARK: - JSON Data Lookup
// All display properties are loaded from a bundled JSON file (WasteKindData.json).
// The JSON is decoded once and cached in a static property for the app's lifetime.

extension WasteKind {

    /// One entry from the JSON file — maps to a single waste category.
    private struct WasteDataEntry: Codable {
        let id: String              // matches the enum rawValue (e.g. "papir")
        let title: String           // full Czech name (e.g. "Papír a kartón")
        let titleShortUpper: String // short uppercase label for the Orloj chart (e.g. "PAPÍR")
        let colorHex: String        // hex color code (e.g. "#2196F3")
        let hint: String            // sorting tip (e.g. "Krabice srovnejte")
        let warning: String         // common mistake (e.g. "Nepatří: mastný papír")
        let education: String       // fun fact about recycling
    }

    /// Static cache — loads and decodes the JSON file once for the entire app lifetime.
    /// Avoids re-reading from disk on every .title, .color, .hint, etc. access.
    private static let allEntries: [WasteDataEntry] = {
        guard let url = Bundle.main.url(forResource: "WasteKindData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([WasteDataEntry].self, from: data) else {
            return []
        }
        return entries
    }()

    /// Finds the matching entry from the cached JSON data.
    private var jsonData: WasteDataEntry? {
        Self.allEntries.first(where: { $0.id == self.rawValue })
    }

    /// Full Czech title (e.g. "Papír a kartón") — shown in WasteDetailView.
    var title: String {
        jsonData?.title ?? self.rawValue.capitalized
    }

    /// Short uppercase label (e.g. "PAPÍR") — shown inside the Orloj chart rows.
    var titleShortUpper: String {
        jsonData?.titleShortUpper ?? self.rawValue.uppercased()
    }

    /// Sorting hint (e.g. "Krabice srovnejte") — shown in the detail sheet.
    var hint: String {
        jsonData?.hint ?? "No hint available."
    }

    /// Common mistake warning (e.g. "Nepatří: mastný papír") — shown in the detail sheet.
    var warning: String {
        jsonData?.warning ?? "No warning available."
    }

    /// Educational text about recycling — shown in the detail sheet.
    var education: String {
        jsonData?.education ?? "Recycling helps the environment."
    }

    /// Category color loaded from hex string in JSON — used for badges, chart segments, pins.
    var color: Color {
        if let hex = jsonData?.colorHex {
            return Color(hex: hex)
        }
        return .gray
    }
}

// MARK: - Color Hex Extension
// Converts a hex string like "#2196F3" to a SwiftUI Color.
// Used by WasteKind.color to turn JSON hex values into actual colors.

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        r = (int >> 16) & 0xFF
        g = (int >> 8) & 0xFF
        b = int & 0xFF
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
