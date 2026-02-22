//
//  FiltersBar.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import SwiftUI

struct FiltersBar: View {
    @Binding var selected: Set<KomoditaFilter>
    @Binding var streetQuery: String
    @State private var showFilters: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - White Search Bar with Red Accent
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .semibold))

                TextField("Search street in Brno...", text: $streetQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(.black)
                    .tint(.red)
                    .autocorrectionDisabled()

                if !streetQuery.isEmpty {
                    Button(action: { streetQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }

                Divider()
                    .frame(height: 24)
                    .overlay(Color.gray.opacity(0.2))

                // Funnel toggle
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showFilters.toggle()
                        if !showFilters { selected.removeAll() }
                    }
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(showFilters ? .red : .gray)
                            .font(.system(size: 18, weight: .semibold))

                        if !selected.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 3, y: -3)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12, corners: showFilters ? [.topLeft, .topRight] : .allCorners)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

            // MARK: - Filter Chips (only chips, no panel)
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(KomoditaFilter.allCases) { filter in
                            FilterChipCompact(
                                filter: filter,
                                isSelected: selected.contains(filter),
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        if selected.contains(filter) {
                                            selected.remove(filter)
                                        } else {
                                            selected.insert(filter)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.white)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Compact Filter Chip
struct FilterChipCompact: View {
    let filter: KomoditaFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 11, weight: .semibold))

                Text(filter.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? Color.red
                    : Color.gray.opacity(0.1)
            )
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(6)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Filter Chip (New Design)
struct FilterChipNew: View {
    let filter: KomoditaFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon or checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.red)
                } else {
                    Image(systemName: filter.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.6))
                }

                // Label
                Text(filter.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                isSelected
                    ? Color.red.opacity(0.12)
                    : Color.white
            )
            .border(
                isSelected ? Color.red : Color.gray.opacity(0.2),
                width: 1.5
            )
            .cornerRadius(10)
        }
    }
}

// MARK: - Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
