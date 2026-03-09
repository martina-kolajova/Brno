//<
//  QuickNavPanel.swift
//  Brno
//
//  "Find nearest container" bottom sheet with overlay dimming.
//  Contains: QuickNavPanel (overlay + dismiss) and QuickNavButtons (horizontal selector).
//

import SwiftUI
import CoreLocation

// MARK: - Quick Navigation Panel

/// Full-screen overlay with a bottom sheet for selecting the nearest waste container type.
struct QuickNavPanel: View {
    @ObservedObject var vm: BrnoMapViewModel
    let allStations: [WasteStation]
    let userLocation: CLLocation

    var body: some View {
        if vm.showNavigationPanel {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            QuickNavButtons(
                onSelect: { filter in
                    dismiss()
                    vm.startQuickNavigation(for: filter, in: allStations, userLocation: userLocation)
                },
                onDismiss: { dismiss() }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(20)
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35)) {
            vm.showNavigationPanel = false
        }
    }
}

// MARK: - Quick Nav Buttons

/// Modern horizontal selector — tap a waste type to navigate to the nearest container.
private struct QuickNavButtons: View {
    var onSelect: (WasteFilter) -> Void
    var onDismiss: () -> Void

    @State private var selected: WasteFilter? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)

            // Header
            HStack {
                Text("Co vyhazuješ?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }

            // Waste type buttons — horizontal row
            HStack(spacing: 10) {
                ForEach(WasteFilter.allCases) { filter in
                    let isActive = selected == filter

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = filter
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onSelect(filter)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isActive ? filter.color : Color(.systemGray6))
                                    .frame(width: 48, height: 48)

                                Image(systemName: filter.iconName)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(isActive ? .white : filter.color)
                            }
                            .scaleEffect(isActive ? 1.08 : 1.0)

                            Text(filter.displayName)
                                .font(.system(size: 10, weight: isActive ? .bold : .medium))
                                .foregroundStyle(isActive ? filter.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
    }
}
