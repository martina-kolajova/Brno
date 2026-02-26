import SwiftUI

// MARK: - Station Map Pin

struct PieChart: View {
    let station: KontejnerStation
    let activeFilters: Set<KomoditaFilter>
    let isSelected: Bool
    let spanDelta: Double

    private var filtersActive: Bool { !activeFilters.isEmpty }

    // Sorted for consistent slice order — prevents visual flickering
    private var matchingFilters: [KomoditaFilter] {
        KomoditaFilter.allCases.filter { station.matches($0) && activeFilters.contains($0) }
    }

    private var pinSize: CGFloat { isSelected ? 24 : 16 }

    var body: some View {
        ZStack {
            if filtersActive {
                // White background circle
                Circle()
                    .fill(.white)
                    .frame(width: pinSize + 4, height: pinSize + 4)
                    .shadow(color: .black.opacity(0.18), radius: isSelected ? 5 : 2)

                if matchingFilters.isEmpty {
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
                    let count = matchingFilters.count
                    let sliceAngle = 360.0 / Double(count)
                    let outerR = pinSize / 2
                    let innerR = pinSize * 0.2

                    ZStack {
                        // Pie slices
                        ForEach(0..<count, id: \.self) { index in
                            PieSlice(
                                startAngle: Angle(degrees: -90 + Double(index) * sliceAngle),
                                endAngle: Angle(degrees: -90 + Double(index + 1) * sliceAngle)
                            )
                            .fill(matchingFilters[index].color)
                        }

                        // Radial divider lines — drawn as a Path for precise angles
                        SliceDividers(
                            count: count,
                            sliceAngle: sliceAngle,
                            innerRadius: innerR,
                            outerRadius: outerR
                        )
                        .stroke(.white, lineWidth: 1.5)

                        // Center hole — donut style
                        Circle()
                            .fill(.white)
                            .frame(width: innerR * 2, height: innerR * 2)
                    }
                    .frame(width: pinSize, height: pinSize)
                    .clipShape(Circle())
                }

            } else {
                // Default: small red dot
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
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: filtersActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Pie Slice Shape

struct PieSlice: Shape {
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

// MARK: - Radial Divider Lines

struct SliceDividers: Shape {
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
