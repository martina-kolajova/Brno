//
//  LoadingView.swift
//  Brno
//
//  Created by Martina Kolajová on 04.02.2026.
//

import SwiftUI

// MARK: - Loading View
// Full-screen loading indicator shown while the API call is in progress.
// Displays a spinning recycling arrow icon (arrow.3.trianglepath).
// Used by: AppView — shown as State 1 when vm.isLoading == true.

struct LoadingView: View {
    /// Controls the continuous rotation animation (0° → 360°).
    @State private var rotation: Double = 0

    var body: some View {
        VStack {
            // Recycling symbol icon — spins continuously while data loads
            Image(systemName: "arrow.3.trianglepath")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(.red)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    // Start infinite rotation — 2 seconds per full turn, never reverses
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}
