//
//  ContentView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WelcomeView()
            InfoView()
            BrnoMapView() // Ta tvoje šedá mapa z předchozích kroků
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }
}
#Preview {
    ContentView()
}
