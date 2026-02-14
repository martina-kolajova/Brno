//
//  FiltersBar.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//


import SwiftUI
import SwiftUI
struct FiltersBar: View {
    @Binding var selected: Set<KomoditaFilter>
    @Binding var streetQuery: String
    // Přidáme tento stav pro schovávání/ukazování:
    @State private var showFilters: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // TLAČÍTKO FILTR (přepíná zobrazení barevných kroužků)
                Button(action: {
                    withAnimation(.spring()) {
                        showFilters.toggle()
                    }
                }) {
                    Image(showFilters ? "funnel_fill" : "funnel") // Bez 'systemName', jen název tvého souboru
                        .resizable() // Důležité u vlastních obrázků!
                        .aspectRatio(contentMode: .fit)
                        .padding(12) // Aby trychtýř nebyl nalepený na okrajích kruhu
                        .frame(width: 45, height: 45)
                        .foregroundStyle(.red) // Bude fungovat, jen pokud je obrázek typu "Template Image" v Assets
                        .background(
                            Circle()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.15), radius: 4)
                        )
                }

                // VYHLEDÁVÁNÍ ULICE
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.gray)
                    TextField("Hledat ulici v Brně...", text: $streetQuery)
                }
                .padding(.horizontal)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 22).fill(.white).shadow(radius: 2))
            }
            .padding(.horizontal)

            // BAREVNÉ FILTRY (Ukážou se jen po kliku na ikonu filtru)
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(KomoditaFilter.allCases) { filter in
                            FilterTag(filter: filter, isSelected: selected.contains(filter)) {
                                if selected.contains(filter) {
                                    selected.remove(filter)
                                } else {
                                    selected.insert(filter)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
struct FilterTag: View {
    let filter: KomoditaFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Ikona komodity
                Image(systemName: filter.iconName)
                    .font(.system(size: 14, weight: .bold))
                
                // Název komodity (volitelné, pokud chceš jen ikony, smaž Text)
                Text(filter.displayName)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : filter.color)
            .frame(width: 55, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? filter.color : filter.color.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(filter.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}
