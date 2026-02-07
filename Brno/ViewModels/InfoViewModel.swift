//
//  InfoViewModel.swift
//  Brno
//
//  Created by Martina Kolajová on 06.02.2026.
//


import SwiftUI



@MainActor
class InfoViewModel: ObservableObject {
    // Data ze Service
    @Published var stats: KontejnerStats?
    
    // Stav UI (animace a interakce)
    @Published var step1Offset: CGFloat = 600
    @Published var step2Offset: CGFloat = 600
    @Published var showStats = false
    @Published var showOrloj = false
    @Published var showNumbers = false
    @Published var selectedCategory: WasteKind? = nil
    
    // Funkce pro spuštění animací
    func runFullSequence() {
        let driveAnim = Animation.timingCurve(0.15, 0.85, 0.35, 1.0, duration: 2.5)
        
        // 1. Nájezd textů "Brno, Brno..."
        withAnimation(driveAnim) { step1Offset = 0 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(driveAnim) { self.step2Offset = 0 }
        }
        
        // 2. Zobrazení statistik pod textem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { self.showStats = true }
        }
        
        // 3. START POMALÉHO PŘÍJEZDU ORLOJE (trvá cca 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.82)) {
                self.showOrloj = true
            }
        }
        
        // 4. ZOBRAZENÍ NÁZVŮ (PAPÍR, PLAST...)
        // Časování + 4.2s (2.2s start + 1.5s jízda + malá rezerva) zajistí,
        // že nápisy "vyskočí" až ve chvíli, kdy je orloj usazený.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) {
            withAnimation(.easeIn(duration: 0.5)) {
                self.showNumbers = true
            }
        }
    }
    
    // Pomocná funkce pro nápovědu (přesunuto z View)
    func getHint(for kind: WasteKind) -> String {
        switch kind {
        case .plast: return "PET lahve, kelímky, fólie, sáčky, krabice od mléka (tetrapak), polystyren."
        case .papir: return "Časopisy, noviny, papírové krabice, letáky, obálky s fólií."
        case .sklo: return "Nevratné lahve od nápojů, sklenice od zavařenin, tabulové sklo."
        case .bioodpad: return "Zbytky ovoce a zeleniny, kávová sedlina, tráva, listí, plevel."
        case .textil: return "Čisté oblečení, obuv, bytový textil (vždy zavázané v sáčcích)."
        }
    }
}
