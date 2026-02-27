//
//  QuickNavPanel.swift
//  Brno
//
//  "Find nearest container" bottom sheet with overlay dimming.
//  Contains: QuickNavPanel (overlay + dismiss) and QuickNavButtons (grid of waste types).
//

import SwiftUI
import CoreLocation

// MARK: - Quick Navigation Panel

/// Full-screen overlay with a bottom sheet for selecting the nearest waste container type.
struct QuickNavPanel: View {
    @ObservedObject var vm: BrnoMapViewModel
    let allStations: [KontejnerStation]
    let userLocation: CLLocation

    var body: some View {
        if vm.showNavigationPanel {
            Color.black.opacity(0.25)
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

// MARK: - Quick Nav Buttons Grid

/// Compact grid of waste type buttons — tap one to navigate to the nearest container.
private struct QuickNavButtons: View {
    var onSelect: (KomoditaFilter) -> Void
    var onDismiss: () -> Void

    @State private var selected: KomoditaFilter? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            buttonGrid
            Color.clear.frame(height: 2)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, y: -1)
        .frame(maxHeight: 180)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 24, height: 3)
                .padding(.top, 6)

            HStack {
                Text("Kam s tým?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(.systemGray3))
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 2)
        }
    }

    // MARK: - Button Grid

    private var buttonGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(KomoditaFilter.allCases) { filter in
                    Button {
                        selected = filter
                        onSelect(filter)
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(selected == filter ? Color.red : filter.color.opacity(0.18))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: filter.iconName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selected == filter ? .white : filter.color)
                                )
                            Text(filter.displayName)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(selected == filter ? .red : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
    }
}
