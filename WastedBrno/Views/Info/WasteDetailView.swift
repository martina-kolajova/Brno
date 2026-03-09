//
//  OdpadDetailView.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import SwiftUI

// MARK: - Waste Detail View
// A full-screen sheet showing detailed info about one waste category.
// Opened when the user taps a category row in the Orloj chart on the Info screen.
// All text content (hint, warning, education) comes from WasteKindData.json via WasteKind.
// Sections:
//   1. Category name in large bold text with the category color
//   2. Container count from API statistics
//   3. "Co sem patří" — sorting tips (green card)
//   4. "Pozor, nepatří sem" — common mistakes (red card)
//   5. "Věděli jste, že...?" — fun facts about recycling (blue card)

struct WasteDetailView: View {
    /// The waste category to display (e.g. .papir, .sklo).
    let kind: WasteKind
    /// Number of containers of this type in Brno (from WasteStatistics.byKind).
    let count: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {

                // --- Category title ---
                // Large bold text in the category color (e.g. blue for paper, green for glass)
                Text(kind.titleShortUpper)
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(kind.color)
                    .padding(.top, 15)

                // --- Container count ---
                // Big number from the API + label underneath
                VStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                    Text("KONTEJNERŮ V CELÉM BRNĚ")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                // --- Sorting tips (green card) ---
                // "Co sem patří" — tells users what belongs in this container
                VStack(alignment: .leading, spacing: 15) {
                    Label("CO SEM PATŘÍ", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.green)
                    
                    Text(kind.hint)  // loaded from WasteKindData.json
                        .font(.system(size: 18, weight: .medium))
                        .lineSpacing(6)
                }
                .padding(25)
                .background(Color.green.opacity(0.05))
                .cornerRadius(24)

                // --- Warning (red card) ---
                // "Pozor, nepatří sem" — common mistakes people make
                VStack(alignment: .leading, spacing: 15) {
                    Label("POZOR, NEPATŘÍ SEM", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.red)
                    
                    Text(kind.warning)  // loaded from WasteKindData.json
                        .font(.system(size: 16, weight: .regular))
                }
                .padding(25)
                .background(Color.red.opacity(0.05))
                .cornerRadius(24)

                // --- Fun fact (blue card) ---
                // "Věděli jste, že...?" — educational recycling facts
                VStack(alignment: .leading, spacing: 15) {
                    Text("VĚDĚLI JSTE, ŽE...?")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.blue)
                    
                    Text(kind.education)  // loaded from WasteKindData.json
                        .font(.system(size: 16, weight: .regular))
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .padding(25)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(24)

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
    }
}
