//
//  MagneticButtonStyle.swift
//  Brno
//
//  Created by Martina Kolajová on 16.02.2026.
//
import SwiftUI

struct MagneticButtonStyle: ButtonStyle {
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(configuration.isPressed ? .red : .white)
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(configuration.isPressed ? .white : .red)
                    .shadow(color: .black.opacity(0.15), radius: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
