import SwiftUI
import os

// MARK: - App-level ViewModel
// The top-level view model that manages:
//   1. Loading data from the API (KontejneryService)
//   2. Storing the fetched stations and statistics
//   3. Tracking which tab is currently visible (Welcome → Info → Map)
// Used by: AppView — the root view of the entire app.
// Injected with KontejneryServicing protocol for testability (can swap in MockKontejneryService).

@MainActor
final class AppViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.app.wastedbrno", category: "AppViewModel")

    /// Currently active tab index: 0 = Welcome, 1 = Info, 2 = Map.
    @Published var selectedTab = 0

    /// Aggregated waste statistics (total containers, stations, breakdown by type).
    /// Nil until the API call completes.
    @Published var stats: WasteStatistics?

    /// All waste stations fetched from the API — passed down to BrnoView for map pins.
    @Published var allStations: [WasteStation] = []

    /// True while the API call is in progress — AppView shows a loading spinner.
    @Published var isLoading = true

    /// If the API call fails, this holds the error message — AppView shows a retry screen.
    @Published var loadError: String?

    /// The service that fetches data from the Brno open data API.
    /// Injected via init so unit tests can pass in a mock.
    private let service: KontejneryServicing

    init(service: KontejneryServicing = KontejneryService()) {
        self.service = service
    }

    /// Fetches all container data from the API.
    /// Called once on app launch (from AppView.task) and when the user taps Retry.
    func loadData() async {
        logger.info("📡 Loading data started")
        isLoading = true
        loadError = nil

        do {
            let result = try await service.fetchAllData()
            stats = result.stats
            allStations = result.stations
            logger.info("✅ Loaded \(result.stations.count) stations, \(result.stats.totalContainers) containers")

            // Brief delay (0.5s) so the loading screen doesn't flash too quickly
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Animate the transition from loading screen → Welcome screen
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
