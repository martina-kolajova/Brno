import Foundation
import CoreLocation

// MARK: - Container Station Model

struct WasteStation: Identifiable {
    let id: String
    let nazev: String
    let komodity: [String]
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Filter Matching

extension WasteStation {
    /// Returns true if the station has containers matching the given filter.
    /// Uses matchKey (e.g. "pap") instead of displayName for more robust matching
    /// against komodity strings like "Papír a kartón".
    func matches(_ filter: WasteFilter) -> Bool {
        komodity.contains { $0.lowercased().contains(filter.matchKey) }
    }

    /// Returns the first matching filter (used for dominant color).
    func dominantFilter() -> WasteFilter? {
        WasteFilter.allCases.first { matches($0) }
    }

    /// Returns deduplicated matching filters — prevents duplicate icons
    /// (e.g. "Sklo bílé" + "Sklo barevné" both map to .sklo → one icon).
    var matchingFilters: [WasteFilter] {
        WasteFilter.allCases.filter { matches($0) }
    }
}
