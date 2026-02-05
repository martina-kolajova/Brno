//
//  LoadingView.swift
//  Brno
//
//  Created by Martina Kolajová on 04.02.2026.
//

import SwiftUI

struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 25) {
            // Symbol recyklace (šipky v trojúhelníku)
            Image(systemName: "arrow.3.trianglepath")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .foregroundStyle(.red) // Ladíme k barvě "Bordel"
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    // Nekonečná lineární rotace (2 sekundy na jednu otočku)
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Hledám kontejnery...")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
