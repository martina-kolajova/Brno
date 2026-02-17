//
//  MagneticButtonStyle.swift
//  Brno
//
//  Created by Martina Kolajová on 16.02.2026.
//
import SwiftUI

struct MagneticButtonStyle: ButtonStyle {
    var isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold)) // keep original size
            .foregroundStyle(isActive ? .red : .white)  // 🔁 reversed
            .frame(width: 50, height: 50)               // keep original frame
            .background(
                Circle()
                    .fill(isActive ? .white : .red)     // 🔁 reversed
                    .shadow(color: .black.opacity(0.15), radius: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
