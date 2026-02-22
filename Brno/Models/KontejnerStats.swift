import Foundation

// MARK: - Container Statistics

struct KontejnerStats: Equatable {
    let totalContainers: Int
    let totalStations: Int
    let byKind: [WasteKind: Int]
}
