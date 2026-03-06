//
//  OdpadDetailView.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import SwiftUI


struct WasteDetailView: View {
    let kind: WasteKind
    let count: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {

                // Název kategorie - Barva teď jde z JSONu přes kind.color
                Text(kind.titleShortUpper)
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(kind.color)
                    .padding(.top, 15)

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

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
    }
}


