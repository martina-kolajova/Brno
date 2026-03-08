//
//  DetailStationPanel.swift
//  Brno
//
//  Created by Martina Kolajová on 08.02.2026.
//

import SwiftUI
import CoreLocation

// MARK: - Detail Station Panel
// The bottom sheet that appears when the user taps a station pin on the map.
// Shows: station name, location, walking distance/time, waste type icons, and a "Navigate" button.
// Uses SwiftUI's presentationDetents — collapsed (70pt) or expanded.
// Used by: BrnoView → .sheet(item: $vm.selectedStation)

struct DetailStationPanel: View {
    /// The station the user tapped on.
    let station: WasteStation
    /// Walking info string (e.g. "350 m • 5 min") — nil if no route calculated yet.
    let navInfo: String?
    /// Called when the user taps the "Navigovat ke košu" button.
    var onNavigate: () -> Void
    /// Controls the sheet height — .height(70) = collapsed, .medium/.large = expanded.
    @Binding var detent: PresentationDetent

    /// True when the sheet is in its smallest (collapsed) state.
    private var isCollapsed: Bool { detent == .height(70) }

    var body: some View {
        Group {
            if isCollapsed {
                Color.clear  // collapsed → show nothing (just the drag handle)
            } else {
                content      // expanded → show full station detail
            }
        }
        .background(Color.white)
    }

    // MARK: - Content
    // The full expanded view with header, waste icons, and navigate button.

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                Divider()
                commodityRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                bottomCTA
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            .background(Color.white)
        }
    }

    // MARK: - Header
    // Shows station name, "Brno, Česká republika" subtitle, and walking info badge.

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(station.nazev)
                    .font(.system(size: 22, weight: .bold))
                Text("Brno, Česká republika")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let info = navInfo, !info.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                    Text(info).font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(.systemGray6)))
            }
        }
    }

    // MARK: - Commodity Icons (deduplicated)
    // Horizontal row of coloured circles showing which waste types the station accepts.
    // Uses matchingFilters to prevent duplicates (e.g. two "Sklo" entries → one icon).

    private var commodityRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(station.matchingFilters) { filter in
                    Image(systemName: filter.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .background(filter.color.opacity(0.18))
                        .foregroundStyle(filter.color)
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Navigate Button
    // Red full-width button at the bottom — calculates a walking route to this station.

    private var bottomCTA: some View {
        Button(action: onNavigate) {
            Text("Navigovat ke košu")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}
