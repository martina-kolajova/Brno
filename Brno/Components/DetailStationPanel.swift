//
//  DetailStationPanel.swift
//  Brno
//
//  Created by Martina Kolajová on 08.02.2026.
//

import SwiftUI
import CoreLocation



struct DetailStationPanel: View {
    let station: KontejnerStation
    let navInfo: String?
    var onNavigate: () -> Void
    var onClose: () -> Void
    @Binding var detent: PresentationDetent

    private var isCollapsed: Bool { detent == .height(70) }

    var body: some View {
        Group {
            if isCollapsed {
                // ✅ prázdné tělo – systém ukáže jen šedou lištu (grabber)
                Color.clear
            } else {
                content
            }
        }
        .background(Color.white)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                Divider()
                commodityRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 120)
        }
        .overlay(alignment: .bottom) {
            bottomCTA
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
                .background(Color.white)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(station.ulice)
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

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
    }

    private var commodityRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(station.komodity, id: \.self) { kom in
                    if let filter = KomoditaFilter.allCases.first(where: { kom.contains($0.rawValue) || $0.rawValue.contains(kom) }) {
                        Image(systemName: filter.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 42, height: 42)
                            .background(filter.color.opacity(0.18))
                            .foregroundStyle(filter.color)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.vertical, 6)
        }
        // ✅ nepřidávej žádné gesture tady
    }

    private var bottomCTA: some View {
        Button(action: onNavigate) {
            Text("Navigovat k cíli")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.red)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}
