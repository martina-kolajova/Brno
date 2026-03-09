//
//  WasteStatsChart.swift
//  Brno
//
//  Orloj-style waste statistics chart for the Info screen.
//  Displays waste categories in a custom curved shape with horizontal dividers.
//  Contains: WasteStatsChart, OrlojShape (private), OrlojInnerLines (private).
//

import SwiftUI

// MARK: - Waste Stats Chart (Orloj)
// A custom chart inspired by the Prague Orloj astronomical clock.
// Displays waste categories as tappable rows inside a curved shape.
// Each row shows an upward chevron (↑) + category name (e.g. "PAPÍR").
// Tapping a row opens a WasteDetailView sheet with sorting tips.
// Used by: InfoView — the statistics/info screen (Tab 1).

/// Orloj-inspired chart showing waste category names as tappable rows.
struct WasteStatsChart: View {
    /// Waste statistics from the API — used to determine what to show.
    let stats: WasteStatistics?
    /// Whether to show the category labels inside the chart (animated in by InfoViewModel).
    let showNumbers: Bool
    /// Callback when a category row is tapped — opens the detail sheet in InfoView.
    var onSelect: (WasteKind) -> Void
    
    /// The order in which categories appear from top to bottom inside the chart.
    private let order: [WasteKind] = [.papir, .plast, .bioodpad, .sklo, .textil]
    /// Vertical positions of the horizontal dividers (as fractions of total height).
    /// 6 cuts create 5 rows — one for each waste category.
    private let yCuts: [CGFloat] = [0.20, 0.36, 0.52, 0.68, 0.84, 0.98]

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width * 0.82, 320)  // max width capped at 320pt
            let h = geo.size.height

            ZStack {
                // White fill with subtle shadow — the chart background
                OrlojShape()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

                // Red outline stroke — the chart border
                OrlojShape()
                    .stroke(Color.red, lineWidth: 5)

                // Horizontal red dividers between rows — clipped to the Orloj shape
                OrlojInnerLines(yCuts: yCuts, red: .red)
                    .clipShape(OrlojShape())

                // Category labels — appear after the chart entrance animation finishes
                if showNumbers {
                    ForEach(0..<order.count, id: \.self) { i in
                        // Calculate the vertical center of this row
                        let midY = (yCuts[i] + yCuts[i+1]) / 2 * h
                        
                        // Tappable row — chevron.up above the category name
                        Button(action: { onSelect(order[i]) }) {
                            VStack(spacing: 3) {
                                // Small upward arrow hint — indicates the row is tappable
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.gray.opacity(0.6))

                                // Category name (e.g. "PAPÍR", "SKLO")
                                Text(order[i].titleShortUpper)
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(.black)
                            }
                            .frame(width: w, height: (yCuts[i+1] - yCuts[i]) * h)
                            .contentShape(Rectangle())  // make the entire row tappable
                        }
                        .position(x: w / 2, y: midY)
                    }
                }
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity)  // center horizontally
        }
    }
}

// MARK: - Helper Shapes

/// Custom curved outline shape inspired by the Prague Orloj clock.
/// Narrow at top (pointed), wide at bottom — creates the distinctive silhouette.
/// Uses two cubic Bézier curves (left side + right side) meeting at the top point.
private struct OrlojShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let topY = h * 0.03      // top point of the shape
        let bottomY = h * 0.98   // bottom edge of the shape
        // Start at bottom-left, curve up to top centre, curve down to bottom-right, close
        path.move(to: CGPoint(x: w * 0.22, y: bottomY))
        path.addCurve(to: CGPoint(x: w * 0.5, y: topY), control1: CGPoint(x: w * 0.18, y: h * 0.70), control2: CGPoint(x: w * 0.2, y: h * 0.05))
        path.addCurve(to: CGPoint(x: w * 0.78, y: bottomY), control1: CGPoint(x: w * 0.8, y: h * 0.05), control2: CGPoint(x: w * 0.82, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.22, y: bottomY))
        path.closeSubpath()
        return path
    }
}

/// Horizontal divider lines inside the Orloj shape.
/// Drawn at each yCut position to separate the category rows.
/// Clipped to OrlojShape so the lines don't extend beyond the curved border.
private struct OrlojInnerLines: View {
    let yCuts: [CGFloat]  // vertical positions (fractions of height)
    let red: Color        // divider colour

    var body: some View {
        GeometryReader { geo in
            // Draw lines between the first and last cut (skip the outer edges)
            ForEach(1..<(yCuts.count - 1), id: \.self) { i in
                Rectangle()
                    .fill(red)
                    .frame(width: geo.size.width, height: 2.5)
                    .position(x: geo.size.width/2, y: yCuts[i] * geo.size.height)
            }
        }
    }
}
