import SwiftUI

// MARK: - App-level ViewModel (data loading)

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var stats: KontejnerStats?
    @Published var allStations: [KontejnerStation] = []
    @Published var isLoading = true

    private let service: KontejneryServicing

    init(service: KontejneryServicing = KontejneryService()) {
        self.service = service
    }

    func loadData() async {
        do {
            let result = try await service.fetchAllData()
            stats = result.stats

            // Brief delay so the loading screen doesn't flash
            try? await Task.sleep(nanoseconds: 1_300_000_000)

            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }

            allStations = result.stations
        } catch {
            isLoading = false
        }
    }
}
