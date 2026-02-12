//
//  OdpadDetailView.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import SwiftUI

import SwiftUI

struct OdpadDetailView: View {
    let kind: WasteKind
    let count: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Vrchní linka
                Capsule()
                    .frame(width: 40, height: 6)
                    .foregroundStyle(.gray.opacity(0.3))
                    .padding(.top, 15)

                // Název kategorie - Barva teď jde z JSONu přes kind.color
                Text(kind.titleShortUpper)
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(kind.color)

                // Hlavní statistika z API
                VStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                    Text("KONTEJNERŮ V CELÉM BRNĚ")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                // Sekce: Co sem patří (z tvého Enumu)
                VStack(alignment: .leading, spacing: 15) {
                    Label("CO SEM PATŘÍ", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.green)
                    
                    Text(kind.hint)
                        .font(.system(size: 18, weight: .medium))
                        .lineSpacing(6)
                }
                .padding(25)
                .background(Color.green.opacity(0.05))
                .cornerRadius(24)

                // Sekce: Varování (Z JSONu)
                VStack(alignment: .leading, spacing: 15) {
                    Label("POZOR, NEPATŘÍ SEM", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.red)
                    
                    Text(kind.warning)
                        .font(.system(size: 16, weight: .regular))
                }
                .padding(25)
                .background(Color.red.opacity(0.05))
                .cornerRadius(24)

                // Sekce: Edukace (Z JSONu)
                VStack(alignment: .leading, spacing: 15) {
                    Text("VĚDĚLI JSTE, ŽE...?")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.blue)
                    
                    Text(kind.education)
                        .font(.system(size: 16, weight: .regular))
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .padding(25)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(24)

                Button(action: { dismiss() }) {
                    Text("ZAVŘÍT")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity) // První frame pro šířku
                        .frame(height: 56)          // Druhý frame pro výšku
                        .background(Color.black)
                        .cornerRadius(18)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .padding(.horizontal)
        }
    }
}

//
//struct OdpadDetailView: View {
//    let kind: WasteKind
//    let count: Int
//    let hint: String
//    @Environment(\.dismiss) var dismiss
//
//    var body: some View {
//        // ScrollView zajistí, že se tam vejde libovolné množství textu
//        ScrollView {
//            VStack(spacing: 30) {
//                // Vrchní linka
//                Capsule()
//                    .frame(width: 40, height: 6)
//                    .foregroundStyle(.gray.opacity(0.3))
//                    .padding(.top, 15)
//
//                // Název kategorie
//                Text(kind.titleShortUpper)
//                    .font(.system(size: 44, weight: .black))
//                    .foregroundStyle(.red)
//
//                // Hlavní statistika
//                VStack(spacing: 0) {
//                    Text("\(count)")
//                        .font(.system(size: 80, weight: .black, design: .rounded))
//                    Text("KONTEJNERŮ V CELÉM BRNĚ")
//                        .font(.caption.bold())
//                        .foregroundStyle(.secondary)
//                }
//
//                // Sekce: Co sem patří
//                VStack(alignment: .leading, spacing: 15) {
//                    Label("CO SEM PATŘÍ", systemImage: "checkmark.circle.fill")
//                        .font(.system(size: 14, weight: .black))
//                        .foregroundStyle(.green)
//                    
//                    Text(hint)
//                        .font(.system(size: 18, weight: .medium))
//                        .lineSpacing(6)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(25)
//                .background(Color.green.opacity(0.05))
//                .cornerRadius(24)
//
//                // --- PROSTOR PRO EDUKACI ---
//                VStack(alignment: .leading, spacing: 15) {
//                    Text("VĚDĚLI JSTE, ŽE...?")
//                        .font(.system(size: 14, weight: .black))
//                        .foregroundStyle(.blue)
//                    
//                    Text("Recyklací jedné tuny \(kind.title.lowercased())u ušetříte energii odpovídající měsíčnímu provozu jedné domácnosti.")
//                        .font(.system(size: 16, weight: .regular))
//                        .italic()
//                        .foregroundStyle(.secondary)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(25)
//                .background(Color.blue.opacity(0.05))
//                .cornerRadius(24)
//                
//                // Tady můžeš přidávat další edukativní bloky...
//
//                Button(action: { dismiss() }) {
//                    Text("ZAVŘÍT")
//                        .font(.headline)
//                        .foregroundStyle(.white)
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 56)
//                        .background(Color.black)
//                        .cornerRadius(18)
//                }
//                .padding(.top, 20)
//                .padding(.bottom, 40)
//            }
//            .padding(.horizontal)
//        }
//    }
//}
