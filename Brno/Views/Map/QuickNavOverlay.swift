import SwiftUI
import CoreLocation

// MARK: - Quick Navigation Overlay

struct QuickNavOverlay: View {
    @ObservedObject var vm: BrnoMapViewModel
    let allStations: [KontejnerStation]
    let userLocation: CLLocation

    var body: some View {
        if vm.showNavigationPanel {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            QuickNavButtons(
                onSelect: { filter in
                    dismiss()
                    vm.startQuickNavigation(for: filter, in: allStations, userLocation: userLocation)
                },
                onDismiss: { dismiss() }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(20)
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35)) {
            vm.showNavigationPanel = false
        }
    }
}
