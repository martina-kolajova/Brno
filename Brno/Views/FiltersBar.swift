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
    var onPlusTap: () -> Void // Nová akce pro plusko

    private let brnoRed = Color.red

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kontejnery")
                .font(.headline)
                .foregroundStyle(brnoRed)
                .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(KomoditaFilter.allCases, id: \.self) { f in
                        FilterChip(
                            title: shortName(f),
                            isOn: selected.contains(f),
                            color: brnoRed
                        ) {
                            toggle(f)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            // VYHLEDÁVÁNÍ + PLUS TLAČÍTKO
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(brnoRed)

                TextField("Zadejte ulici...", text: $streetQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if !streetQuery.isEmpty {
                    Button { streetQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
                
                // Tlačítko PLUS přímo v liště
                Button(action: onPlusTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(brnoRed)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(brnoRed.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
        .cornerRadius(18)
        .shadow(radius: 6)
        .padding(.horizontal, 12)
    }

    private func toggle(_ f: KomoditaFilter) {
        if selected.contains(f) { selected.remove(f) }
        else { selected.insert(f) }
        if selected.isEmpty {
            selected = Set(KomoditaFilter.allCases)
        }
    }

    private func shortName(_ f: KomoditaFilter) -> String {
        switch f {
        case .papir: return "Papír"
        case .plast: return "Plast"
        case .bio: return "Bio"
        case .skloBarevne: return "Sklo"
        case .skloBile: return "Sklo bílé"
        case .textil: return "Textil"
        }
    }
}

// Pomocné tlačítko pro kategorii
private struct FilterChip: View {
    let title: String
    let isOn: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(isOn ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isOn ? color : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
