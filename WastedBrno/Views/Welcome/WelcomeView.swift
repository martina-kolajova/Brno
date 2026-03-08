//
//  WelcomeView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI

// MARK: - Welcome View
// The first screen the user sees (Tab 0) — an animated splash/onboarding.
// Animation sequence:
//   1. Trash can stands upright (1.1s pause)
//   2. Trash can tips 90° to the left and turns red (0.45s)
//   3. Lid opens with a spring bounce (0.35s)
//   4. Everything slides off-screen to the left (3s)
//   5. Automatically advances to InfoView (Tab 1)
// No user interaction needed — it plays automatically on launch.

struct WelcomeView: View {
    /// Called when the animation finishes — AppView advances to Tab 1 (InfoView).
    var onFinished: () -> Void

    // Animation states — each controls one phase of the sequence
    @State private var tipped = false        // trash can has fallen 90° to the left
    @State private var lidOpen = false       // lid is open after the can tipped
    @State private var exitOffset: CGFloat = 0  // slides everything off-screen

    /// Accent color changes from black → red when the can tips over.
    private var accentColor: Color { tipped ? .red : .black }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 3) {

                // --- Trash can ---
                // Tips 90° left, pivoting from its bottom-left corner.
                // Lid opens after tipping with a spring bounce.
                TrashCanView(
                    lidAngle: lidOpen ? -60 : 0,
                    color: accentColor
                )
                .scaleEffect(0.92)
                .rotationEffect(
                    .degrees(tipped ? -90 : 0),
                    anchor: .bottomLeading  // pivot point = bottom-left corner
                )
                .offset(x: 70)

                // --- App title ---
                HStack(spacing: 3) {
                    Text("Wasted")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(accentColor)  // black → red when can tips

                    Text("Brno")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
            .offset(x: exitOffset)  // slides entire VStack off-screen
        }
        .onAppear {
            // --- Animation timeline ---
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
                        withAnimation(.easeIn(duration: 0.5)) {
                            exitOffset = -600
                        }

                        // Phase D: Transition to InfoView (Tab 1)
                        // Wait for the exit slide to finish BEFORE switching tabs
                        // — prevents two animations fighting each other (the old 3s slide
                        //   was still running when the TabView swipe started at 0.6s).
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                .offset(x: 70)
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
