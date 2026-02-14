//
//  PiePinViewModel.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.
//


import SwiftUI

class PiePinViewModel: ObservableObject {
    let station: KontejnerStation
    let activeFilters: Set<KomoditaFilter>
    
    init(station: KontejnerStation, activeFilters: Set<KomoditaFilter>) {
        self.station = station
        self.activeFilters = activeFilters
    }
    
    // 1. Tady určíme, co se v koláči vůbec objeví
    var displayedKomodity: [String] {
        // Pokud není filtr, ukaž vše
        if activeFilters.isEmpty {
            return station.komodity
        }
        
        // Filtrujeme: v poli zůstanou jen ty, co uživatel CHCE vidět
        return station.komodity.filter { komStr in
            activeFilters.contains { filter in
                komStr.localizedCaseInsensitiveContains(filter.rawValue)
            }
        }
    }
    
    // 2. Úhel počítáme dynamicky podle počtu AKTUÁLNĚ viditelných prvků
    func angle(for index: Int) -> Angle {
        let total = displayedKomodity.count
        guard total > 0 else { return .degrees(0) }
        
        // Rozdělí 360 stupňů rovnoměrně mezi viditelné kusy
        return .degrees(Double(index) / Double(total) * 360.0 - 90.0)
    }
    
    // Pomocná funkce pro koncový úhel (aby na sebe dílky navazovaly)
    func endAngle(for index: Int) -> Angle {
        let total = displayedKomodity.count
        guard total > 0 else { return .degrees(0) }
        return .degrees(Double(index + 1) / Double(total) * 360.0 - 90.0)
    }

    func colorFor(_ kind: String) -> Color {
        let s = kind.lowercased()
        if s.contains("plast") || s.contains("kov") { return .yellow }
        if s.contains("pap") { return .blue }
        if s.contains("sklo") { return .green }
        if s.contains("textil") { return .purple }
        if s.contains("bio") { return .brown }
        return .red
    }
}
