//
//  ButtonStyles.swift
//  Brno
//
//  Custom button styles used across the app.
//

import SwiftUI

// MARK: - FAB Button Style

/// Circular floating action button style with active/inactive states.
/// Active: white background with colored border and icon.
/// Inactive: colored background with white icon.
struct FABButtonStyle: ButtonStyle {
    var color: Color = .red
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isActive ? color : .white)
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(isActive ? Color.white : color)
                    .shadow(color: color.opacity(0.35), radius: configuration.isPressed ? 2 : 6, y: 2)
            )
            .overlay(
                Circle()
                    .strokeBorder(isActive ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
