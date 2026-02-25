//
//  ContentView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = AppViewModel()

    var body: some View {
        ZStack {
            if vm.isLoading {
                LoadingView()
            } else if let error = vm.loadError {
                // Error state with retry
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
            } else {
                TabView(selection: $vm.selectedTab) {
                    WelcomeView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            vm.selectedTab = 1
                        }
                    })
                    .tag(0)

                    InfoView(stats: vm.stats, onContinue: {
                        withAnimation { vm.selectedTab = 2 }
                    })
                    .tag(1)

                    // Map is only created when the user navigates to it
                    Group {
                        if vm.selectedTab == 2 {
                            BrnoView(allStations: vm.allStations)
                        } else {
                            Color.clear
                        }
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        .task {
            await vm.loadData()
        }
    }
}

#Preview {
    ContentView()
}
