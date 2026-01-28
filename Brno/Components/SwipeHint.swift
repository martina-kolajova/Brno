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
    var count: Int = 3
    var size: CGFloat = 28
    var spacing: CGFloat = 12
    var travel: CGFloat = 16
    var duration: Double = 1.3
    var color: Color = .red

    @State private var offset: CGFloat = 0

    var body: some View {
        Group {
            if direction == .right {
                HStack(spacing: spacing) { arrows }
                    .offset(x: offset)
            } else {
                VStack(spacing: spacing) { arrows }
                    .offset(y: offset)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                offset = travel
            }
        }
    }

    private var arrows: some View {
        ForEach(0..<count, id: \.self) { i in
            Image(systemName: direction == .right ? "chevron.right" : "chevron.down")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(color)
                .opacity(1.0 - Double(i) * 0.25)
        }
    }
}
