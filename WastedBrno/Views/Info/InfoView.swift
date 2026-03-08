//
//  InfoView.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import SwiftUI

// MARK: - Info View
// The second screen (Tab 1) — shows waste statistics and the Orloj chart.
// Animation sequence (managed by InfoViewModel):
//   1. Title "Brno, Brno" slides in from the right
//   2. Subtitle "kontejnerů plno." slides in
//   3. Stats line fades in (total containers & stations)
//   4. Orloj chart rises from the bottom
//   5. Category labels appear inside the chart
// Tapping a category opens a WasteDetailView sheet with sorting tips.
// Swiping right advances to the Map screen (Tab 2).

struct InfoView: View {
    /// Controls the step-by-step animation sequence.
    @StateObject private var viewModel = InfoViewModel()
    /// Waste statistics passed in from AppViewModel — shown in the header and chart.
    var stats: WasteStatistics?
    /// Called when the user swipes to advance to the map screen.
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                // --- Title section ---
                // Two lines that slide in from the right with a custom timing curve.
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brno, Brno")
                        .font(.system(size: 34, weight: .bold))
                        .offset(x: viewModel.step1Offset)  // starts at 600, animates to 0
                    
                    Text("kontejnerů plno.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.red)
                        .offset(x: viewModel.step2Offset)  // starts at 600, animates to 0 (delayed)

                    // Stats subtitle — fades in after both title lines have arrived
                    if let stats = stats {
                        Text("Celkem \(stats.totalContainers) kontejnerů • \(stats.totalStations) stanovišť")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.gray)
                            .padding(.top, 6)
                            .opacity(viewModel.showStats ? 1 : 0)
                    }
                }
                .padding(.horizontal, 25).padding(.top, 20)

                Spacer()

                // --- Orloj chart ---
                // Custom curved shape showing waste categories as tappable rows.
                // Rises from the bottom with a spring animation.
                if viewModel.showOrloj {
                    WasteStatsChart(stats: stats, showNumbers: viewModel.showNumbers) { kind in
                        viewModel.selectedCategory = kind  // opens the detail sheet
                    }
                    .frame(height: 500)
                    .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

                    // Hint text — tells the user the chart rows are tappable
                    if viewModel.showNumbers {
                        Text("Klikni na kategorii pro více info")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                    }
                }

                Spacer()
                
                // Animated arrow hint — tells the user to swipe right to continue
                SwipeIndicator(direction: .right)
                    .opacity(viewModel.showNumbers ? 1 : 0)  // only visible after chart is fully shown
                    .frame(maxWidth: .infinity)
            }
        }
        // Detail sheet — opens when the user taps a category in the Orloj chart
        .sheet(item: $viewModel.selectedCategory) { kind in
            WasteDetailView(
                kind: kind,
                count: stats?.byKind[kind] ?? 0
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Start the animation sequence when the screen becomes visible
            viewModel.runFullSequence()
        }
        .onDisappear {
            // Cancel pending animation timers so they don't fire
            // during the transition to the map screen and cause a stutter
            viewModel.cancelSequence()
        }
    }
}
