import SwiftUI

// MARK: - Info Screen ViewModel

@MainActor
final class InfoViewModel: ObservableObject {

    // MARK: - Animation state

    @Published var step1Offset: CGFloat = 600
    @Published var step2Offset: CGFloat = 600
    @Published var showStats = false
    @Published var showOrloj = false
    @Published var showNumbers = false
    @Published var selectedCategory: WasteKind?

    // MARK: - Animation sequence

    func runFullSequence() {
        let driveAnim = Animation.timingCurve(0.15, 0.85, 0.35, 1.0, duration: 2.5)

        // Step 1: Slide in title text
        withAnimation(driveAnim) { step1Offset = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(driveAnim) { self.step2Offset = 0 }
        }

        // Step 2: Show statistics subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { self.showStats = true }
        }

        // Step 3: Animate orloj (clock shape) entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.82)) {
                self.showOrloj = true
            }
        }

        // Step 4: Show category labels after orloj settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) {
            withAnimation(.easeIn(duration: 0.5)) {
                self.showNumbers = true
            }
        }
    }
}
