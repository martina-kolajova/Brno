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
    // Přidáme novou proměnnou pro text z navigace
    let navInfo: String?
    
    var onNavigate: () -> Void
    var onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.ulice)
                        .font(.system(size: 18, weight: .bold))
                    Text("Brno, Česká republika")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Tady se zobrazí informace z navigace (např. 1.5 km • 18 min)
                if let info = navInfo, !info.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                        Text(info)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1)) // Jemně červená, aby to ladilo
                    
                    .foregroundStyle(.red)
                    .cornerRadius(10)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.5))
                        .font(.title2)
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                ForEach(station.komodity, id: \.self) { kom in
                    if let filter = KomoditaFilter.allCases.first(where: { kom.contains($0.rawValue) || $0.rawValue.contains(kom) }) {
                        Image(systemName: filter.iconName)
                            .font(.system(size: 16))
                            .frame(width: 38, height: 38)
                            .background(filter.color.opacity(0.2))
                            .foregroundStyle(filter.color)
                            .clipShape(Circle())
                    }
                }
            }
            
            Button(action: onNavigate) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.fill")
                    Text("Navigovat k cíli")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(16)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: -5)
        .padding(.horizontal, 16)
    }
}
