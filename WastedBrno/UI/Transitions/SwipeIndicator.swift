//
//  SwipeHint.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//


import SwiftUI

// MARK: - Swipe Indicator
// Animated arrow hint that tells the user to swipe in a direction.
// Shows a row of bars (thin → thick) that bounce back and forth.
// Supports two directions:
//   .right → horizontal bars bouncing right (used on InfoView to hint "swipe to map")
//   .down  → vertical bars bouncing down (could be used for "pull down" hints)
// Used by: InfoView — appears after the Orloj chart animation finishes.

struct SwipeIndicator: View {
    /// Which direction the indicator points.
    enum Direction {
        case right, down
    }

    let direction: Direction
    var count: Int = 4           // number of bars
    var height: CGFloat = 28     // bar height (or width if vertical)
    var minWidth: CGFloat = 2    // thinnest bar
    var maxWidth: CGFloat = 8    // thickest bar
    var spacing: CGFloat = 16    // gap between bars
    var travel: CGFloat = 16     // how far the bars bounce (in points)
    var duration: Double = 1.3   // time for one bounce cycle (seconds)
    var color: Color = .red      // bar colour

    /// Animated offset — bounces between 0 and `travel`.
    @State private var offset: CGFloat = 0

    var body: some View {
        Group {
            if direction == .right {
                // Horizontal layout — bars bounce to the right
                HStack(spacing: spacing) { bars }
                    .offset(x: offset)
            } else {
                // Vertical layout — bars bounce downward
                VStack(spacing: spacing) { bars }
                    .offset(y: offset)
            }
        }
        .onAppear {
            // Start infinite bounce animation — easeInOut creates a smooth back-and-forth
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                offset = travel
            }
        }
    }

    /// Generates the row of bars — each progressively wider and slightly more transparent.
    private var bars: some View {
        ForEach(0..<count, id: \.self) { i in
            Rectangle()
                .fill(color)
                .frame(
                    width: barWidth(for: i),
                    height: height
                )
                .opacity(1.0 - Double(i) * 0.15)  // first bar = full opacity, last = faded
        }
    }

    /// Calculates bar width — linearly interpolates from minWidth to maxWidth.
    /// First bar is thinnest (tail), last bar is thickest (arrow head).
    private func barWidth(for index: Int) -> CGFloat {
        let t = CGFloat(index) / CGFloat(max(count - 1, 1))
        return minWidth + t * (maxWidth - minWidth)
    }
}
