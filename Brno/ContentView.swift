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
    @State private var allStations: [KontejnerStation] = []
    @State private var isLoading = true
    
    private let service = KontejneryService()

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else {
                TabView(selection: $selectedTab) {
                    // 0. WELCOME SCREEN
                    WelcomeView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            selectedTab = 1
                        }
                    })
                    .tag(0)

                    // 1. INFO SCREEN (Orloj)
                    InfoView(stats: stats, onContinue: {
                        withAnimation { selectedTab = 2 }
                    })
                    .tag(1)

                    // 2. MAPA - TADY JE TA ZMĚNA
                    Group {
                        if selectedTab == 2 {
                            // Mapa se narodí až když na ni uživatel klikne/swipne
                            BrnoView(allStations: allStations)
                        } else {
                            // Dokud jsme na Welcome/Info, mapa neexistuje a nežere výkon
                            Color.clear
                        }
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        .task {
            do {
                // 1. Stáhneme statistiky
                let statsData = try await service.fetchStats()
                
                await MainActor.run {
                    self.stats = statsData
                }

                // --- TADY JE ZMĚNA ---
                // I když jsou data hned, počkáme 1.2 sekundy.
                // To zajistí, že LoadingView "neblikne" a UI se v klidu připraví.
                try? await Task.sleep(nanoseconds: 1_300_000_000)

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.isLoading = false
                    }
                }

                // 2. VLNA: Mapa až POTÉ, co loading zmizel
                let stationsData = try await service.fetchStations(limit: 200000)
                await MainActor.run {
                    self.allStations = stationsData
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
