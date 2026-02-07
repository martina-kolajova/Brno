import SwiftUI

@MainActor
final class InfoViewModel: ObservableObject {
    @Published var stats: KontejnerStats?
    @Published var selectedCategory: WasteKind? = nil
    
    // Stavy animací
    @Published var step1Offset: CGFloat = 600
    @Published var step2Offset: CGFloat = 600
    @Published var showStats = false
    @Published var showOrloj = false
    @Published var showNumbers = false
    
    private let service: KontejneryService
    
    init(service: KontejneryService = KontejneryService()) {
        self.service = service
    }
    
    func loadDataAndAnimate() async {
        // Načtení dat
        do {
            self.stats = try await service.fetchStats()
        } catch {
            print("Chyba načítání: \(error)")
        }
        
        // Spuštění sekvence
        runSequence()
    }
    
    private func runSequence() {
        let driveAnim = Animation.timingCurve(0.15, 0.85, 0.35, 1.0, duration: 2.5)
        
        withAnimation(driveAnim) { step1Offset = 0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(driveAnim) { self.step1Offset = 0; self.step2Offset = 0 }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { self.showStats = true }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) { self.showOrloj = true }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation { self.showNumbers = true }
        }
    }
}