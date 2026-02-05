//
//  ContentView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var stats: KontejnerStats? = nil
    @State private var isLoading = true
    private let service = KontejneryService()

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    WelcomeView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            selectedTab = 1
                        }
                    })
                    .tag(0)

                    // InfoView a Mapu obalíme do podmínky, aby se začaly
                    // vykreslovat až v momentě, kdy jsou potřeba.
                    if selectedTab >= 1 {
                        InfoView(stats: stats, onContinue: {
                            withAnimation { selectedTab = 2 }
                        })
                        .tag(1)
                    }

                    if selectedTab == 2 {
                        KontejneryMapScreen().tag(2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        .task {
            do {
                // 1. Začneme stahovat data hned
                let fetchedStats = try await service.fetchStats()
                
                // 2. POVINNÁ PAUZA (např. 1.5 vteřiny)
                // I když jsou data stažená hned, necháme šipky točit,
                // aby se systém stihl připravit na animaci.
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    self.stats = fetchedStats
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.isLoading = false
                    }
                }
            } catch {
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
