//
//  InfoView 2.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import SwiftUI

struct InfoView: View {
    @StateObject private var viewModel = InfoViewModel()
    var stats: KontejnerStats?
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                // TEXTOVÁ SEKCE
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brno, Brno")
                        .font(.system(size: 34, weight: .bold))
                        .offset(x: viewModel.step1Offset)
                    
                    Text("kontejnerů plno.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.red)
                        .offset(x: viewModel.step2Offset)

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

                // ORLOJ
                if viewModel.showOrloj {
                    OrlojStatsView(stats: stats, showNumbers: viewModel.showNumbers) { kind in
                        viewModel.selectedCategory = kind
                    }
                    .frame(height: 500)
                    .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                Spacer()
                
                SwipeHint(direction: .right)
                    .opacity(viewModel.showNumbers ? 1 : 0)
                    .frame(maxWidth: .infinity)
            }
        }
        // V InfoView.swift najdi tuto část:
        .sheet(item: $viewModel.selectedCategory) { kind in
            OdpadDetailView(
                kind: kind,
                count: stats?.byKind[kind] ?? 0
            )
            .presentationDetents([.large]) // Změna z .medium na .large pro celou obrazovku
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.runFullSequence()
        }
    }
}

