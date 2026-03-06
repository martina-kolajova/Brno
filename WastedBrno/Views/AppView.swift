//
//  ContentView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI

// MARK: - Root View
// ContentView is the app's entry point after launch.
// It decides what the user sees based on the current loading state:
//   • Loading spinner  → while data is being fetched from the API
//   • Error screen     → if the network request failed (with a Retry button)
//   • Main app (TabView) → once data is ready
//
// The main app uses a paged TabView (swipe-based, no tab bar) with 3 screens:
//   Tab 0 – WelcomeView   (intro / onboarding)
//   Tab 1 – InfoView       (waste statistics & charts)
//   Tab 2 – BrnoView       (interactive map with waste stations)

struct AppView: View {

    /// The app-level view-model: fetches station data from the API,
    /// computes statistics, and tracks which tab is active.
    @StateObject private var vm = AppViewModel()

    var body: some View {
        ZStack {

            // --- State 1: Loading ---
            // Shown while the API call is in progress.
            if vm.isLoading {
                LoadingView()

            // --- State 2: Error ---
            // Shown if the API call failed. Displays the error message
            // and a Retry button that re-triggers the network request.
            } else if let error = vm.loadError {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                    Text("Failed to load data")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await vm.loadData() }
                    } label: {
                        Text("Retry")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.red))
                    }
                }
                .padding(40)

            // --- State 3: Main app ---
            // Data loaded successfully — show the three-screen paged TabView.
            } else {
                TabView(selection: $vm.selectedTab) {

                    // Tab 0: Welcome / onboarding screen.
                    // When the user taps "Continue", animate to the Info tab.
                    WelcomeView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            vm.selectedTab = 1
                        }
                    })
                    .tag(0)

                    // Tab 1: Info screen — shows waste statistics and charts.
                    // "Continue" advances to the map.
                    InfoView(stats: vm.stats, onContinue: {
                        withAnimation { vm.selectedTab = 2 }
                    })
                    .tag(1)

                    // Tab 2: Map screen — interactive map with all waste stations.
                    // Wrapped in a Group so the heavy Map view is only created
                    // when the user actually navigates to this tab (lazy loading).
                    Group {
                        if vm.selectedTab == 2 {
                            BrnoView(allStations: vm.allStations, onBack: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    vm.selectedTab = 1
                                }
                            })
                        } else {
                            Color.clear   // lightweight placeholder while on other tabs
                        }
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))  // swipe between tabs, no dots
                .ignoresSafeArea()
            }
        }
        // Kick off the API fetch as soon as the view appears.
        .task {
            await vm.loadData()
        }
    }
}

#Preview {
    AppView()
}
