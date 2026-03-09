//
//  FiltersBar.swift
//  Brno
//
//  Search bar with filter chips and autocomplete suggestions.
//  Contains: FiltersBar, FilterChip (private), SearchSuggestions.
//

import SwiftUI
import MapKit

// MARK: - Filters Bar

/// Top search bar with expandable filter chips and street search autocomplete.
struct FiltersBar: View {
    @Binding var selected: Set<WasteFilter>
    @Binding var streetQuery: String
    /// Callback to navigate back to the Info screen (orloj button).
    var onBack: (() -> Void)? = nil
    @State private var showFilters: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterChips
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            // Back button — tapping navigates back to the Info screen.
            if let onBack {
                Button(action: { withAnimation { onBack() } }) {
                    Image(systemName: "chevron.backward.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .semibold))
            }

            TextField("Hledej ulicu ve Štatlu...", text: $streetQuery)
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
    }

    // MARK: - Filter Chips Row

    @ViewBuilder
    private var filterChips: some View {
        if showFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WasteFilter.allCases) { filter in
                        FilterChip(
                            filter: filter,
                            isSelected: selected.contains(filter),
                            action: {
                                // No withAnimation here — animating 200 pin changes
                                // at once causes visible lag. The chip itself animates
                                // via its own internal animation.
                                if selected.contains(filter) {
                                    selected.remove(filter)
                                } else {
                                    selected.insert(filter)
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
}

// MARK: - Filter Chip (Private)

/// Single filter chip button — shows waste type icon and name.
private struct FilterChip: View {
    let filter: WasteFilter
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
            .background(isSelected ? Color.red : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(6)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Search Suggestions Dropdown

/// Autocomplete dropdown for street search results.
struct SearchSuggestions: View {
    let results: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion, String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(results, id: \.self) { result in
                    Button {
                        onSelect(result, result.title)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title).foregroundStyle(.red)
                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal, 20)
        .padding(.top, 5)
        .frame(maxHeight: 200)
    }
}
