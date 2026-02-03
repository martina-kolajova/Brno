//
//  WelcomeView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//


import SwiftUI

struct WelcomeView: View {
    @State private var dropped = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack(spacing: 3) {
                    
                    Text("Bordel")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(dropped ? .red : .black)
                    // levá strana dolů (pravá "drží")
                        .rotationEffect(.degrees(dropped ? -12 : 0), anchor: .bottomTrailing)
                        .scaleEffect(dropped ? 0.97 : 1.0, anchor: .bottomTrailing)
                        .offset(y: dropped ? 2 : 0)
                    
                    Text("Brno")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(.black)
                }
                
            }
            .padding(.horizontal, 24)
            VStack {
                Spacer()
                SwipeHint(direction: .right)
                    .padding(.bottom, 36)
            }
            .onAppear {
                // krátká pauza, ať to nepůsobí "trhavě" hned po otevření
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.35)) {
                        dropped = true
                        
                        
                    }
                }
            }
        }
    }
}



#Preview { WelcomeView() }
