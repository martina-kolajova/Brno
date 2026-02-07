//
//  KontejneryMapScreen.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//

import SwiftUI
import MapKit


struct BrnoView: View {
    let allStations: [KontejnerStation]
    
    @State private var selectedStationID: String? = nil
    @State private var selected: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
    @State private var streetQuery: String = ""
    
    @State private var camera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                ForEach(filteredStations) { st in
                    Annotation(st.title, coordinate: st.coordinate) {
                        // Předáváme i informaci o aktivních filtrech pro správné vykreslení výsečí
                        PiePinView(
                            station: st,
                            isSelected: selectedStationID == st.id,
                            activeFilters: selected
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                selectedStationID = (selectedStationID == st.id) ? nil : st.id
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()

            FiltersBar(selected: $selected, streetQuery: $streetQuery)
                .padding(.top, 12)
        }
    }

    // --- OPRAVENÁ FILTRACE ---
    private var filteredStations: [KontejnerStation] {
        allStations.filter { st in
            // 1. Filtr ulice (ponecháme)
            let matchStreet = streetQuery.isEmpty || st.ulice.localizedCaseInsensitiveContains(streetQuery)
            
            // 2. OPRAVENÝ FILTR KOMODIT
            // Projdeme všechny komodity na daném stanovišti
            let hasVisibleKomodita = st.komodity.contains { komStr in
                // Stanoviště je viditelné, pokud se text komodity shoduje s některým AKTIVNÍM filtrem
                selected.contains { filter in
                    // Použijeme localizedCaseInsensitiveContains pro maximální shodu
                    // Předpokládám, že filter.rawValue obsahuje klíčová slova jako "plast", "pap", "sklo"
                    komStr.localizedCaseInsensitiveContains(filter.rawValue)
                }
            }
            
            return matchStreet && hasVisibleKomodita
        }
    }
}

// MARK: - Opravený PiePinView
struct PiePinView: View {
    let station: KontejnerStation
    let isSelected: Bool
    let activeFilters: Set<KomoditaFilter>
    
    // Získáme pouze ty komodity, které uživatel nezablokoval filtrem
    private var visibleKomodity: [String] {
        station.komodity.filter { komStr in
            activeFilters.contains { filter in
                komStr.localizedCaseInsensitiveContains(filter.rawValue)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Pozadí pinu
            Circle()
                .fill(.white)
                .frame(width: isSelected ? 46 : 16, height: isSelected ? 46 : 16)
                .shadow(color: .black.opacity(0.2), radius: isSelected ? 5 : 2)
            
            if isSelected {
                // Vykreslíme výseče POUZE pro aktivní (filtrované) komodity
                let items = visibleKomodity
                ForEach(0..<items.count, id: \.self) { index in
                    PieSlice(
                        startAngle: .degrees(Double(index) / Double(items.count) * 360.0 - 90.0),
                        endAngle: .degrees(Double(index + 1) / Double(items.count) * 360.0 - 90.0)
                    )
                    .fill(colorFor(items[index]))
                    .frame(width: 40, height: 40)
                }
                
                // Donut efekt
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
            } else {
                // Malá tečka - barva podle první viditelné komodity
                Circle()
                    .fill(colorFor(visibleKomodity.first ?? ""))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private func colorFor(_ string: String) -> Color {
        let s = string.lowercased()
        if s.contains("plast") || s.contains("kov") { return .yellow }
        if s.contains("pap") { return .blue }
        if s.contains("sklo") { return .green }
        if s.contains("textil") { return .orange }
        if s.contains("bio") { return .brown }
        return .gray
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
