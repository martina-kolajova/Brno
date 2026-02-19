//
//  QuickNavButtons.swift
//  Brno
//
//  Created by Martina Kolajová on 18.02.2026.
//
import SwiftUI


struct QuickNavButtons: View {
    var onSelect: (KomoditaFilter) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nejbližší kontejner")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(KomoditaFilter.allCases) { filter in
                        Button { onSelect(filter) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filter.iconName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(filter.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(filter.color)
                            .padding(.horizontal, 12)  // reduced from 14
                            .padding(.vertical, 9)
                            .background(filter.color.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)  // reduced from 20
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8)
        )
        .padding(.horizontal, 16)
    }
}
//struct QuickNavButtons: View {
//    var onSelect: (KomoditaFilter) -> Void
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(KomoditaFilter.allCases) { filter in
//                    Button { onSelect(filter) } label: {
//                        VStack(spacing: 4) {
//                            Image(systemName: filter.iconName).font(.title3)
//                            Text(filter.displayName)
//                                .font(.system(size: 10, weight: .bold))
//                                .lineLimit(1)
//                        }
//                        .foregroundStyle(.white).frame(width: 70, height: 70)
//                        .background(filter.color).clipShape(RoundedRectangle(cornerRadius: 15))
//                    }
//                }
//            }
//            .padding(.horizontal, 16).padding(.vertical, 8)
//        }
//        .background(Color.white.opacity(0.95)).cornerRadius(20).padding(.horizontal, 16)
//    }
//}
//
