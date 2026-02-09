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
    
    var visibleKomodity: [String] {
        station.komodity.filter { komStr in
            activeFilters.contains { filter in
                komStr.localizedCaseInsensitiveContains(filter.rawValue)
            }
        }
    }
    
    var dominantColor: Color {
        colorFor(visibleKomodity.first ?? "")
    }
    
    func angle(for index: Int) -> Angle {
        let total = visibleKomodity.count
        guard total > 0 else { return .degrees(0) }
        return .degrees(Double(index) / Double(total) * 360.0 - 90.0)
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
