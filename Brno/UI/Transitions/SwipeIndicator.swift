//
//  SwipeHint.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//


import SwiftUI


struct SwipeHint: View {
    enum Direction {
        case right, down
    }

    let direction: Direction
    var count: Int = 4
    var height: CGFloat = 28
    var minWidth: CGFloat = 2
    var maxWidth: CGFloat = 8
    var spacing: CGFloat = 16
    var travel: CGFloat = 16
    var duration: Double = 1.3
    var color: Color = .red

    @State private var offset: CGFloat = 0

    var body: some View {
        Group {
            if direction == .right {
                HStack(spacing: spacing) { bars }
                    .offset(x: offset)
            } else {
                VStack(spacing: spacing) { bars }
                    .offset(y: offset)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                offset = travel
            }
        }
    }

    private var bars: some View {
        ForEach(0..<count, id: \.self) { i in
            Rectangle()
                .fill(color)
                .frame(
                    width: barWidth(for: i),
                    height: height
                )
                .opacity(1.0 - Double(i) * 0.15)
        }
    }

    private func barWidth(for index: Int) -> CGFloat {
        let t = CGFloat(index) / CGFloat(max(count - 1, 1))
        return minWidth + t * (maxWidth - minWidth)
    }
}
