import Foundation

// MARK: - Container Statistics
// Holds the aggregated numbers shown on the Info screen.
// Built once from the API response by KontejneryService.buildResult().

struct WasteStatistics: Equatable {
    /// Total number of individual containers across all stations.
    let totalContainers: Int
    /// Total number of unique station locations (each may have multiple containers).
    let totalStations: Int
    /// Breakdown by waste type — e.g. [.papir: 320, .sklo: 180, ...].
    /// Used by the Orloj chart to show category counts.
    let byKind: [WasteKind: Int]
}
