import Foundation
import CoreLocation

// MARK: - Container Station Model
// Represents a single waste collection station in Brno.
// Each station has a unique ID, a name, a list of waste types (komodity),
// and GPS coordinates for placing pins on the map.
// One station can have multiple containers (e.g. paper + glass at the same spot).

struct WasteStation: Identifiable, Equatable {
    /// Unique station ID from the API (stanoviste_ogc_fid).
    let id: String
    /// Human-readable name of the station (e.g. street name or location description).
    let nazev: String
    /// List of waste types accepted at this station (e.g. ["Papír", "Sklo barevné"]).
    let komodity: [String]
    /// GPS coordinates used to place the pin on the map.
    let coordinate: CLLocationCoordinate2D

    /// Manual Equatable — CLLocationCoordinate2D doesn't conform automatically.
    /// Lets SwiftUI skip re-rendering pins that haven't changed.
    static func == (lhs: WasteStation, rhs: WasteStation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Filter Matching
// These methods let us quickly check which waste types a station accepts.
// Used by the map to decide which pins to show based on active filters.

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
