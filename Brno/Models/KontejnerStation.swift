import Foundation
import CoreLocation

// MARK: - Container Station Model

struct KontejnerStation: Identifiable {
    let id: String
    let nazev: String
    let komodity: [String]
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Filter Matching

extension KontejnerStation {
    /// Returns true if the station has containers matching the given filter.
    func matches(_ filter: KomoditaFilter) -> Bool {
        komodity.contains { $0.lowercased().contains(filter.rawValue.lowercased()) }
    }

    /// Returns the first matching filter (used for dominant color).
    func dominantFilter() -> KomoditaFilter? {
        KomoditaFilter.allCases.first { matches($0) }
    }
}
