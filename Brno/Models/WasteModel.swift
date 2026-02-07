//
//  WasteKind.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import Foundation
import SwiftUI

enum WasteKind: String, CaseIterable, Hashable, Identifiable {
    case papir = "papir"
    case plast = "plast"
    case sklo = "sklo"
    case bioodpad = "bioodpad"
    case textil = "textil"
    
    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .papir: return "Papír"
        case .plast: return "Plast"
        case .sklo: return "Sklo"
        case .bioodpad: return "Bioodpad"
        case .textil: return "Textil"
        }
    }
    
    var titleShortUpper: String {
        self.title.uppercased()
    }
    
    var hint: String {
        switch self {
        case .plast: return "PET lahve, kelímky, fólie, krabice od mléka, polystyren."
        case .papir: return "Časopisy, noviny, krabice, letáky, obálky s fólií."
        case .sklo: return "Nevratné lahve, sklenice od zavařenin, tabulové sklo."
        case .bioodpad: return "Zbytky ovoce a zeleniny, kávová sedlina, tráva, listí."
        case .textil: return "Čisté oblečení, obuv, bytový textil v sáčcích."
        }
    }
}

struct KontejnerStats: Equatable {
    let totalContainers: Int
    let totalStations: Int
    let byKind: [WasteKind: Int]
}
