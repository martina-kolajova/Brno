//
//  QuickNavButtons.swift
//  Brno
//
//  Created by Martina Kolajová on 18.02.2026.
//
import SwiftUI

// MARK: - Quick Navigation Bottom Sheet

struct QuickNavButtons: View {
    var onSelect: (KomoditaFilter) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle + header
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Find Nearest Container")
                            .font(.system(size: 16, weight: .bold))
                        Text("Navigate to the closest bin by type")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(.systemGray3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            Divider()

            // Container type grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(KomoditaFilter.allCases) { filter in
                    Button { onSelect(filter) } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(filter.color.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Image(systemName: filter.iconName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(filter.color)
                            }
                            Text(filter.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Bottom safe area spacer
            Color.clear.frame(height: 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: -4)
    }
}
