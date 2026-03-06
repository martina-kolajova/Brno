import SwiftUI
import os

// MARK: - App-level ViewModel (data loading)

@MainActor
final class AppViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.app.wastedbrno", category: "AppViewModel")
    @Published var selectedTab = 0
    @Published var stats: WasteStatistics?
    @Published var allStations: [WasteStation] = []
    @Published var isLoading = true
    @Published var loadError: String?

    private let service: KontejneryServicing

    init(service: KontejneryServicing = KontejneryService()) {
        self.service = service
    }

    func loadData() async {
        logger.info("📡 Loading data started")
        isLoading = true
        loadError = nil

        do {
            let result = try await service.fetchAllData()
            stats = result.stats
            allStations = result.stations
            logger.info("✅ Loaded \(result.stations.count) stations, \(result.stats.totalContainers) containers")

            // Brief delay so the loading screen doesn't flash
            try? await Task.sleep(nanoseconds: 500_000_000)

            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
        } catch {
            logger.error("❌ Data load failed: \(error.localizedDescription)")
            withAnimation {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}
