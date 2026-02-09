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
    var onQuickNavTap: () -> Void // Akce pro červenou šipku

    var body: some View {
        VStack(spacing: 12) {
            // 1. ŘÁDEK: Hledání a Rychlá navigace
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                
                TextField("Hledat ulici v Brně...", text: $streetQuery)
                    .textInputAutocapitalization(.words)
                
                if !streetQuery.isEmpty {
                    Button { streetQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                    }
                }
                
                Divider().frame(height: 20)
                
                // Červená šipka - Teď vypadá jako "Start"
                Button(action: onQuickNavTap) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // 2. ŘÁDEK: Filtry (kompaktní a elegantní)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(KomoditaFilter.allCases, id: \.self) { f in
                        Button { toggle(f) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: f.iconName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(selected.contains(f) ? .white : f.color)
                                    .frame(width: 36, height: 36)
                                    .background(selected.contains(f) ? f.color : f.color.opacity(0.12))
                                    .clipShape(Circle())
                                
                                Text(f.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(selected.contains(f) ? .primary : .secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial) // Efekt skla jako v iOS
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    private func toggle(_ f: KomoditaFilter) {
        withAnimation(.spring(response: 0.3)) {
            if selected.contains(f) {
                if selected.count > 1 { selected.remove(f) }
            } else {
                selected.insert(f)
            }
        }
    }
}

//struct FiltersBar: View {
//    @Binding var selected: Set<KomoditaFilter>
//    @Binding var streetQuery: String
//    var onQuickNavTap: () -> Void // Akce pro červenou šipku
//
//    var body: some View {
//        VStack(spacing: 12) {
//            // HLAVNÍ ŘÁDEK HLEDÁNÍ
//            HStack(spacing: 10) {
//                Image(systemName: "magnifyingglass")
//                    .foregroundStyle(.gray)
//                
//                TextField("Zadejte ulici v Brně...", text: $streetQuery)
//                    .textInputAutocapitalization(.words)
//                
//                if !streetQuery.isEmpty {
//                    Button { streetQuery = "" } label: {
//                        Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
//                    }
//                }
//                
//                Divider().frame(height: 20)
//                
//                // Červená šipka (Rychlá navigace)
//                Button(action: onQuickNavTap) {
//                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
//                        .font(.system(size: 28))
//                        .foregroundStyle(.red)
//                }
//            }
//            .padding(.horizontal, 12).padding(.vertical, 8)
//            .background(Color(.systemBackground))
//            .cornerRadius(12)
//            
//            // FILTRY (Kulaté, malé, přímo v kartě)
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 15) {
//                    ForEach(KomoditaFilter.allCases, id: \.self) { f in
//                        Button { toggle(f) } label: {
//                            VStack(spacing: 4) {
//                                Image(systemName: f.iconName)
//                                    .font(.system(size: 16, weight: .bold))
//                                    .foregroundStyle(selected.contains(f) ? .white : f.color)
//                                    .frame(width: 38, height: 38)
//                                    .background(selected.contains(f) ? f.color : f.color.opacity(0.1))
//                                    .clipShape(Circle())
//                                
//                                Text(f.displayName)
//                                    .font(.system(size: 10, weight: .medium))
//                                    .foregroundStyle(selected.contains(f) ? .primary : .secondary)
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal, 5)
//            }
//        }
//        .padding(12)
//        .background(.ultraThinMaterial)
//        .cornerRadius(20)
//        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
//        .padding(.horizontal, 16)
//    }
//
//    private func toggle(_ f: KomoditaFilter) {
//        withAnimation(.spring(response: 0.3)) {
//            if selected.contains(f) {
//                if selected.count > 1 { selected.remove(f) }
//            } else {
//                selected.insert(f)
//            }
//        }
//    }
//}

