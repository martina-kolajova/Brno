import Foundation

// MARK: - Container Statistics

struct WasteStatistics: Equatable {
    let totalContainers: Int
    let totalStations: Int
    let byKind: [WasteKind: Int]
}
