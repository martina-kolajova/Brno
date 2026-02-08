//
//  PiePinView.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.
//\
import SwiftUI



struct PiePinView: View {
    @ObservedObject var viewModel: PiePinViewModel
    let isSelected: Bool

    var body: some View {
        ZStack {
            // Podkladový bílý kruh (stín a ohraničení)
            Circle()
                .fill(.white)
                .frame(width: isSelected ? 46 : 16, height: isSelected ? 46 : 16)
                .shadow(color: .black.opacity(0.2), radius: isSelected ? 5 : 2)

            if isSelected {
                // ROZBALENÝ STAV (Koláčový graf)
                let visibleItems = viewModel.visibleKomodity
                ForEach(0..<visibleItems.count, id: \.self) { index in
                    PieSlice(
                        startAngle: viewModel.angle(for: index),
                        endAngle: viewModel.angle(for: index + 1)
                    )
                    .fill(viewModel.colorFor(visibleItems[index]))
                    .frame(width: 40, height: 40)
                }
                
                // Bílý střed pro efekt "Donut" grafu
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
            } else {
                // ZMENŠENÝ STAV (Malá tečka)
                // OPRAVA: Index zde neexistuje, bereme barvu první komodity
                Circle()
                    .fill(viewModel.colorFor(viewModel.visibleKomodity.first ?? ""))
                    .frame(width: 12, height: 12)
            }
        }
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
