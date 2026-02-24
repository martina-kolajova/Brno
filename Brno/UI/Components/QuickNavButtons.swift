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

    @State private var selected: KomoditaFilter? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Minimalist header
            VStack(spacing: 4) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 24, height: 3)
                    .padding(.top, 6)

                HStack {
                    Text("Find Nearest Container")
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

            Divider()

            // Compact container type grid
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

            Color.clear.frame(height: 2)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, y: -1)
        .frame(maxHeight: 180)
    }
}
