import SwiftUI

// MARK: - Station Map Pin

struct PiePinView: View {
    let station: KontejnerStation
    let activeFilters: Set<KomoditaFilter>
    let isSelected: Bool
    let spanDelta: Double

    // True when at least one filter chip is active
    private var filtersActive: Bool { !activeFilters.isEmpty }

    // Waste types at this station matching active filters
    private var matchingFilters: [KomoditaFilter] {
        KomoditaFilter.allCases.filter { station.matches($0) && activeFilters.contains($0) }
    }

    // Pin size — smaller base, grows when selected
    private var pinSize: CGFloat { isSelected ? 20 : 12 }

    var body: some View {
        ZStack {
            if filtersActive {
                // Pie chart mode
                Circle()
                    .fill(.white)
                    .frame(width: pinSize + 5, height: pinSize + 5)
                    .shadow(color: .black.opacity(0.18), radius: isSelected ? 5 : 2)

                ZStack {
                    if matchingFilters.isEmpty {
                        Circle().fill(Color(.systemGray4))
                    } else {
                        ForEach(0..<matchingFilters.count, id: \.self) { index in
                            PieSlice(
                                startAngle: Angle(degrees: Double(index) * (360.0 / Double(matchingFilters.count))),
                                endAngle: Angle(degrees: Double(index + 1) * (360.0 / Double(matchingFilters.count)))
                            )
                            .fill(matchingFilters[index].color)
                        }
                    }
                }
                .frame(width: pinSize, height: pinSize)

                Circle()
                    .fill(.white)
                    .frame(width: pinSize * 0.32, height: pinSize * 0.32)

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
