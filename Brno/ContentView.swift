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
