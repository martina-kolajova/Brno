//
//  PiePinView.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.
//\
import SwiftUI



struct PiePinView: View {
    let station: KontejnerStation
    let activeFilters: Set<KomoditaFilter>
    let isSelected: Bool
    let spanDelta: Double

    private var pinSize: CGFloat {
        let base = max(8, min(24, 0.15 / spanDelta * 10))
        return isSelected ? base * 1.4 : base
    }

    var matchingFilters: [KomoditaFilter] {
        KomoditaFilter.allCases.filter { filter in
            station.matches(filter) && activeFilters.contains(filter)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: pinSize + 6, height: pinSize + 6)
                .shadow(radius: isSelected ? 4 : 2)

            ZStack {
                if matchingFilters.isEmpty {
                    Circle().fill(.gray.opacity(0.4))
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
                .frame(width: pinSize * 0.35, height: pinSize * 0.35)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: spanDelta)
    }
}

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

//
//struct PiePinView: View {
//    @ObservedObject var viewModel: PiePinViewModel
//    let isSelected: Bool
//
//    var body: some View {
//        ZStack {
//            // 1. Podkladový bílý kruh (stín a ohraničení)
//            Circle()
//                .fill(.white)
//                // Pokud je vybraný, je větší, pokud ne, je to standardní malý koláček
//                .frame(width: isSelected ? 48 : 34)
//                .shadow(color: .black.opacity(0.2), radius: isSelected ? 5 : 2)
//
//            // 2. KOLÁČOVÝ GRAF - Teď je vidět VŽDY
//            let visibleItems = viewModel.displayedKomodity
//
//            ForEach(0..<visibleItems.count, id: \.self) { index in
//                PieSlice(
//                    startAngle: viewModel.angle(for: index),
//                    endAngle: viewModel.endAngle(for: index) // Použijeme novou funkci
//                )
//                .fill(viewModel.colorFor(visibleItems[index]))
//                .frame(width: isSelected ? 42 : 28, height: isSelected ? 42 : 28)
//            }
//            
//            
//            // 3. Bílý střed pro efekt "Donut" grafu
//            Circle()
//                .fill(.white)
//                .frame(width: isSelected ? 18 : 12)
//        }
//        // Jemná animace při rozbalení
//        .scaleEffect(isSelected ? 1.2 : 1.0)
//        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
//    }
//}
//struct PieSlice: Shape {
//    var startAngle: Angle
//    var endAngle: Angle
//
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let center = CGPoint(x: rect.midX, y: rect.midY)
//        path.move(to: center)
//        path.addArc(center: center, radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
//        path.closeSubpath()
//        return path
//    }
//}
