import Foundation
import SwiftUI

// MARK: - Waste Kind

enum WasteKind: String, CaseIterable, Hashable, Identifiable {
    case papir, plast, sklo, bioodpad, textil

    var id: String { self.rawValue }
}

// MARK: - JSON Data Lookup

extension WasteKind {

    private struct WasteDataEntry: Codable {
        let id: String
        let title: String
        let titleShortUpper: String
        let colorHex: String
        let hint: String
        let warning: String
        let education: String
    }

    /// Loads the matching entry from WasteKindData.json.
    private var jsonData: WasteDataEntry? {
        guard let url = Bundle.main.url(forResource: "WasteKindData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([WasteDataEntry].self, from: data) else {
            return nil
        }
        return entries.first(where: { $0.id == self.rawValue })
    }

    var title: String {
        jsonData?.title ?? self.rawValue.capitalized
    }

    var titleShortUpper: String {
        jsonData?.titleShortUpper ?? self.rawValue.uppercased()
    }

    var hint: String {
        jsonData?.hint ?? "No hint available."
    }

    var warning: String {
        jsonData?.warning ?? "No warning available."
    }

    var education: String {
        jsonData?.education ?? "Recycling helps the environment."
    }

    var color: Color {
        if let hex = jsonData?.colorHex {
            return Color(hex: hex)
        }
        return .gray
    }
}

// MARK: - Color Hex Extension

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
