//
//  DetailStationPanel.swift
//  Brno
//
//  Created by Martina Kolajová on 08.02.2026.
//

import SwiftUI
import CoreLocation

struct DetailStationPanel: View {
    let station: WasteStation
    let navInfo: String?
    var onNavigate: () -> Void
    @Binding var detent: PresentationDetent

    private var isCollapsed: Bool { detent == .height(70) }

    var body: some View {
        Group {
            if isCollapsed {
                Color.clear
            } else {
                content
            }
        }
        .background(Color.white)
    }

    // MARK: - Content

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
