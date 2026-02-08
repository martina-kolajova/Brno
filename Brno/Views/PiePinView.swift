//
//  PiePinView.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.
//


import SwiftUI

struct PiePinView: View {
    // Použijeme ViewModel pro logiku pinu
    @StateObject private var viewModel: PiePinViewModel
    let isSelected: Bool
    
    init(station: KontejnerStation, isSelected: Bool, activeFilters: Set<KomoditaFilter>) {
        self.isSelected = isSelected
        // Inicializace ViewModelu s daty ze stanice
        _viewModel = StateObject(wrappedValue: PiePinViewModel(
            station: station,
            activeFilters: activeFilters
        ))
    }
    
    var body: some View {
        ZStack {
            // Základní kruh (pozadí pinu)
            Circle()
                .fill(.white)
                .frame(width: isSelected ? 46 : 16, height: isSelected ? 46 : 16)
                .shadow(color: .black.opacity(0.2), radius: isSelected ? 5 : 2)
            
            if isSelected {
                // Vykreslení barevných výsečí (donutu)
                let visibleItems = viewModel.visibleKomodity
                ForEach(0..<visibleItems.count, id: \.self) { index in
                    PieSlice(
                        startAngle: viewModel.angle(for: index),
                        endAngle: viewModel.angle(for: index + 1)
                    )
                    .fill(viewModel.colorFor(visibleItems[index]))
                    .frame(width: 40, height: 40)
                }
                
                // Vnitřní bílý kruh (vytváří efekt donutu)
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
            } else {
                // Malý jednoduchý puntík, když není pin rozkliknutý
                Circle()
                    .fill(viewModel.dominantColor)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

// Tvar pro jednotlivé výseče
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