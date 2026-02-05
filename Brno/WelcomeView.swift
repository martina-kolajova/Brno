//
//  WelcomeView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//


import SwiftUI

struct WelcomeView: View {
    @State private var colorProgress: Double = 0
    @State private var dropped = false
    var onFinished: () -> Void // <--- Přidáno
    @State private var exitOffset: CGFloat = 0 // 1. Přidáme stav pro odjezd
    
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack(spacing: 3) {
                    Text("Bordel")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(dropped ? .red : .black)
                        .rotationEffect(.degrees(dropped ? -12 : 0), anchor: .bottomTrailing)
                        .scaleEffect(dropped ? 0.97 : 1.0, anchor: .bottomTrailing)
                        .offset(y: dropped ? 2 : 0)
                    
                    Text("Brno")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(.black)
                }
            }
        }
        .onAppear {
            
            // --- RYCHLOST ZABARVENÍ ---
            // duration: 2.0 znamená, že se nápis barví 2 vteřiny
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                
                // 2. BARVENÍ: Teď se začne plynule barvit (trvá to 2 sekundy)
                withAnimation(.easeInOut(duration: 2.0)) {
                    colorProgress = 1.0
                }
                // FÁZE A: Pád nápisu
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        dropped = true
                    }
                    
                    // FÁZE B: ODJEZD (Tady nastavuješ rychlost)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // RYCHLOST ODJEZDU: duration upravuješ zde (např. 0.8 nebo 1.2)
                        withAnimation(.easeInOut(duration: 3)) {
                            exitOffset = -1000 // Odjede doleva
                        }
                        
                        // Přepnutí proběhne s malým zpožděním po začátku odjezdu
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            onFinished()
                        }
                    }
                }
            }
        }
    }
}

