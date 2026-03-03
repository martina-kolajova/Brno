import SwiftUI

// MARK: - App-level ViewModel (data loading)

@MainActor
final class AppViewModel: ObservableObject {
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
        isLoading = true
        loadError = nil

        do {
            let result = try await service.fetchAllData()
            stats = result.stats
            allStations = result.stations

            // Brief delay so the loading screen doesn't flash
            try? await Task.sleep(nanoseconds: 1_300_000_000)

            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
        } catch {
            withAnimation {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}
