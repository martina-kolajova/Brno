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
    let userLocation: CLLocationCoordinate2D?
    var onNavigate: () -> Void
    var onClose: () -> Void
    
    // Pomocná funkce pro výpočet vzdálenosti v metrech/kilometrech
    var distanceString: String {
        guard let userLocation else { return "-- m" }
        let start = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let end = CLLocation(latitude: station.coordinate.latitude, longitude: station.coordinate.longitude)
        let distance = start.distance(from: end)
        
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
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
                
                // VZDÁLENOST A BOTIČKY
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk") // Ikona botiček/chůze
                        .font(.subheadline)
                    Text(distanceString)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.trailing, 8)

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.5))
                        .font(.title2)
                }
            }
            
            Divider()
            
            // Ikony kontejnerů
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
            
            // ČERVENÉ TLAČÍTKO
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
