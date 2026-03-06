//
//  WelcomeView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI


// MARK: - Welcome View

struct WelcomeView: View {
    var onFinished: () -> Void

    // Animation states
    @State private var tipped = false      // trash tips 90° left
    @State private var lidOpen = false      // lid opens after tipping
    @State private var exitOffset: CGFloat = 0

    /// Current colour — black at start, red after tipping
    private var accentColor: Color { tipped ? .red : .black }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 3) {

                // Trash can — tips 90° to the left, pivoting from its bottom-left corner
                TrashCanView(
                    lidAngle: lidOpen ? -60 : 0,
                    color: accentColor
                )
                .scaleEffect(0.92) // Slightly smaller than the final size for a subtle "pop" when it falls
                .rotationEffect(
                    .degrees(tipped ? -90 : 0),
                    anchor: .bottomLeading
                )
                .offset(x: 60)

                // App title
                HStack(spacing: 3) {
                    Text("Wasted")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(accentColor)

                    Text("Brno")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
            .offset(x: exitOffset)
        }
        .onAppear {
            // Small initial pause so the screen isn't instant
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {

                // Phase A: Tip the trash can 90° to the left + turn red
                withAnimation(.easeIn(duration: 0.45)) {
                    tipped = true
                }

                // Phase B: Open the lid after the can has fallen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        lidOpen = true
                    }

                    // Phase C: Slide everything off screen to the left
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 3)) {
                            exitOffset = -1000
                        }

                        // Transition to next screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            onFinished()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    WelcomeView(onFinished: {})
}

#Preview("Fallen") {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack(spacing: 3) {
            TrashCanView(lidAngle: -60, color: .red)
                .scaleEffect(0.92)
                .rotationEffect(.degrees(-90), anchor: .bottomLeading)
                .offset(x: 60)
            HStack(spacing: 3) {
                Text("Wasted")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(.red)
                Text("Brno")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(.black)
            }
        }
    }
}
//
