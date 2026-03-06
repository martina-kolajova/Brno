//
//  WasteStatsChart.swift
//  Brno
//
//  Orloj-style waste statistics chart for the Info screen.
//  Displays waste categories in a custom curved shape with horizontal dividers.
//  Contains: WasteStatsChart, OrlojShape (private), OrlojInnerLines (private).
//

import SwiftUI

// MARK: - Waste Stats Chart

/// Orloj-inspired chart showing waste category names as tappable rows.
struct WasteStatsChart: View {
    let stats: WasteStatistics?
    let showNumbers: Bool
    var onSelect: (WasteKind) -> Void
    
    private let order: [WasteKind] = [.papir, .plast, .bioodpad, .sklo, .textil]
    private let yCuts: [CGFloat] = [0.20, 0.36, 0.52, 0.68, 0.84, 0.98]

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width * 0.82, 320)
            let h = geo.size.height

            ZStack {
                OrlojShape()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

                OrlojShape()
                    .stroke(Color.red, lineWidth: 5)

                OrlojInnerLines(yCuts: yCuts, red: .red)
                    .clipShape(OrlojShape())

                if showNumbers {
                    ForEach(0..<order.count, id: \.self) { i in
                        let midY = (yCuts[i] + yCuts[i+1]) / 2 * h
                        
                        Button(action: { onSelect(order[i]) }) {
                            HStack(spacing: 6) {
                                Text(order[i].titleShortUpper)
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(.black)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.gray.opacity(0.6))
                            }
                            .frame(width: w, height: (yCuts[i+1] - yCuts[i]) * h)
                            .contentShape(Rectangle())
                        }
                        .position(x: w / 2, y: midY)
                    }
                }
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Helper Shapes

/// Custom curved outline shape inspired by the Prague Orloj clock.
private struct OrlojShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let topY = h * 0.03
        let bottomY = h * 0.98
        path.move(to: CGPoint(x: w * 0.22, y: bottomY))
        path.addCurve(to: CGPoint(x: w * 0.5, y: topY), control1: CGPoint(x: w * 0.18, y: h * 0.70), control2: CGPoint(x: w * 0.2, y: h * 0.05))
        path.addCurve(to: CGPoint(x: w * 0.78, y: bottomY), control1: CGPoint(x: w * 0.8, y: h * 0.05), control2: CGPoint(x: w * 0.82, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.22, y: bottomY))
        path.closeSubpath()
        return path
    }
}

/// Horizontal divider lines inside the Orloj shape.
private struct OrlojInnerLines: View {
    let yCuts: [CGFloat]
    let red: Color
    var body: some View {
        GeometryReader { geo in
            ForEach(1..<(yCuts.count - 1), id: \.self) { i in
                Rectangle()
                    .fill(red)
                    .frame(width: geo.size.width, height: 2.5)
                    .position(x: geo.size.width/2, y: yCuts[i] * geo.size.height)
            }
        }
    }
}
