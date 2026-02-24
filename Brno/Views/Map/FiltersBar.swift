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
            // MARK: - Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .semibold))

                TextField("Hledej ulicu v Štatlu...", text: $streetQuery)
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

            // MARK: - Filter Chips
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(KomoditaFilter.allCases) { filter in
                            FilterChip(
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
