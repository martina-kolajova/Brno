//
//  StationPin.swift
//  Brno
//
//  Map annotation pin for a waste container station.
//  Shows a red dot by default, or a donut pie chart when filters are active.
//  Contains: StationPin, PieSlice (private), SliceDividers (private).
//

import SwiftUI

// MARK: - Station Pin

/// Map annotation view for a single container station.
/// - No filters: small red dot.
/// - Filters active: donut pie chart showing matching waste types.
struct StationPin: View {
    let station: WasteStation
    let activeFilters: Set<WasteFilter>
    let isSelected: Bool
    let spanDelta: Double

    private var filtersActive: Bool { !activeFilters.isEmpty }

    /// Sorted for consistent slice order — prevents visual flickering
    private var matchingFilters: [WasteFilter] {
        WasteFilter.allCases.filter { station.matches($0) && activeFilters.contains($0) }
    }

    private var pinSize: CGFloat { isSelected ? 24 : 16 }

    var body: some View {
        ZStack {
            if filtersActive {
                activePin
            } else {
                defaultPin
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: filtersActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }

    // MARK: - Default Red Dot

    private var defaultPin: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(isSelected ? 1.0 : 0.85))
                .frame(width: pinSize, height: pinSize)
                .shadow(color: .red.opacity(0.35), radius: isSelected ? 5 : 2)

            if isSelected {
                Circle()
                    .strokeBorder(.white, lineWidth: 2)
                    .frame(width: pinSize, height: pinSize)
            }
        }
    }

    // MARK: - Active Donut Pin

    private var activePin: some View {
        ZStack {
            // White background
            Circle()
                .fill(.white)
                .frame(width: pinSize + 4, height: pinSize + 4)
                .shadow(color: .black.opacity(0.18), radius: isSelected ? 5 : 2)

            if matchingFilters.isEmpty {
                // No match — grey dot
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: pinSize, height: pinSize)
            } else if matchingFilters.count == 1 {
                // Single filter — donut ring
                Circle()
                    .fill(matchingFilters[0].color)
                    .frame(width: pinSize, height: pinSize)
                Circle()
                    .fill(.white)
                    .frame(width: pinSize * 0.4, height: pinSize * 0.4)
            } else {
                // Multiple filters — donut with pie slices + radial dividers
                donutChart
            }
        }
    }

    // MARK: - Donut Chart

    private var donutChart: some View {
        let count = matchingFilters.count
        let sliceAngle = 360.0 / Double(count)
        let outerR = pinSize / 2
        let innerR = pinSize * 0.2

        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                PieSlice(
                    startAngle: Angle(degrees: -90 + Double(index) * sliceAngle),
                    endAngle: Angle(degrees: -90 + Double(index + 1) * sliceAngle)
                )
                .fill(matchingFilters[index].color)
            }

            SliceDividers(
                count: count,
                sliceAngle: sliceAngle,
                innerRadius: innerR,
                outerRadius: outerR
            )
            .stroke(.white, lineWidth: 1.5)

            Circle()
                .fill(.white)
                .frame(width: innerR * 2, height: innerR * 2)
        }
        .frame(width: pinSize, height: pinSize)
        .clipShape(Circle())
    }
}

// MARK: - Pie Slice Shape

/// A single pie slice drawn from the center of a circle.
private struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Slice Dividers

/// Radial lines between pie slices, drawn from inner radius to outer radius.
private struct SliceDividers: Shape {
    let count: Int
    let sliceAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        for i in 0..<count {
            let angle = Angle(degrees: -90 + Double(i) * sliceAngle)
            let cosA = CGFloat(cos(angle.radians))
            let sinA = CGFloat(sin(angle.radians))

            let inner = CGPoint(
                x: center.x + innerRadius * cosA,
                y: center.y + innerRadius * sinA
            )
            let outer = CGPoint(
                x: center.x + outerRadius * cosA,
                y: center.y + outerRadius * sinA
            )

            path.move(to: inner)
            path.addLine(to: outer)
        }

        return path
    }
}
