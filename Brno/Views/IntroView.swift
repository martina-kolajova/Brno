//
//  IntroView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//
import SwiftUI

import SwiftUI

struct InfoView: View {
    var stats: KontejnerStats?
    
    var onContinue: () -> Void      // Bez výchozí hodnoty, aby ji init vyžadoval
    
    // Stavy pro příjezdy zprava
    @State private var step1Offset: CGFloat = 600
    @State private var step2Offset: CGFloat = 600
    
    // Ostatní stavy
    @State private var showStats = false
    @State private var showOrloj = false
    @State private var showNumbers = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                // TEXTOVÁ SEKCE (Přijíždí zprava)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brno, Brno")
                        .font(.system(size: 34, weight: .bold))
                        .offset(x: step1Offset)
                    
                    Text("kontejnerů plno.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.red)
                        .offset(x: step2Offset)

                    if let stats = stats {
                        Text("Celkem \(stats.totalContainers) kontejnerů • \(stats.totalStations) stanovišť")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.gray)
                            .padding(.top, 6)
                            .opacity(showStats ? 1 : 0)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                .drawingGroup()

                Spacer()

                // ORLOJ (Vyjíždí zespodu)
                Group {
                    if showOrloj {
                        OrlojStatsView(stats: stats, showNumbers: showNumbers)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 500)

                Spacer()
                
                // Místo pro SwipeHint
                Color.clear.frame(height: 80)
            }
            
            VStack {
                Spacer()
                SwipeHint(direction: .right)
                    .padding(.bottom, 36)
                    .opacity(showNumbers ? 1 : 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            runFullSequence()
        }
    }

    private func runFullSequence() {
        // Velmi plynulá křivka pro dojezd zprava
        let driveAnim = Animation.timingCurve(0.15, 0.85, 0.35, 1.0, duration: 3)

        // 1. Příjezd "Brno, Brno"
        withAnimation(driveAnim) {
            step1Offset = 0
        }

        // 2. Příjezd "kontejnerů plno" (s malým zpožděním)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(driveAnim) {
                step2Offset = 0
            }
        }

        // 3. Zobrazení statistik
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showStats = true
            }
        }

        // 4. Majestátní výjezd Orloje
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                showOrloj = true
            }
        }

        // 5. Rozsvícení čísel uvnitř Orloje
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeIn(duration: 0.8)) {
                showNumbers = true
            }
        }
    }
}

// MARK: - Upravený OrlojStatsView
private struct OrlojStatsView: View {
    let stats: KontejnerStats?
    let showNumbers: Bool // Nový parametr
    
    private let order: [WasteKind] = [.papir, .plast, .bioodpad, .sklo, .textil]
    private let yCuts: [CGFloat] = [0.20, 0.36, 0.52, 0.68, 0.84, 0.98]
    private let redColor: Color = .red

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width * 0.82, 320)
            let h = geo.size.height

            ZStack {
                OrlojShape()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

                OrlojShape()
                    .stroke(redColor, lineWidth: 5)

                OrlojInnerLines(yCuts: yCuts, red: redColor)
                    .clipShape(OrlojShape())

                // 3. KROK: Čísla se vykreslí jen když je showNumbers true
                if let stats = stats, showNumbers {
                    OrlojRows(stats: stats, order: order, yCuts: yCuts)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .clipShape(OrlojShape())
                }
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - OrlojShape (Tupý vršek + rovný spodek)
private struct OrlojShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let topY = h * 0.03
        let bottomY = h * 0.98
        
        path.move(to: CGPoint(x: w * 0.22, y: bottomY))
        
        path.addCurve(to: CGPoint(x: w * 0.5, y: topY),
                      control1: CGPoint(x: w * 0.18, y: h * 0.70),
                      control2: CGPoint(x: w * 0.2, y: h * 0.05))
        
        path.addCurve(to: CGPoint(x: w * 0.78, y: bottomY),
                      control1: CGPoint(x: w * 0.8, y: h * 0.05),
                      control2: CGPoint(x: w * 0.82, y: h * 0.70))
        
        path.addLine(to: CGPoint(x: w * 0.22, y: bottomY))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - OrlojRows (Menší texty)
private struct OrlojRows: View {
    let stats: KontejnerStats
    let order: [WasteKind]
    let yCuts: [CGFloat]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ForEach(0..<order.count, id: \.self) { i in
                let midY = (yCuts[i] + yCuts[i+1]) / 2 * h
                
                HStack(spacing: 5) {
                    Text(order[i].titleShortUpper)
                        .font(.system(size: 15, weight: .black))
                    Text(":")
                        .font(.system(size: 15, weight: .black))
                    Text("\(stats.byKind[order[i], default: 0])")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .position(x: w / 2, y: midY)
            }
        }
    }
}

// MARK: - OrlojInnerLines
private struct OrlojInnerLines: View {
    let yCuts: [CGFloat]
    let red: Color
    var body: some View {
        GeometryReader { geo in
            ForEach(1..<(yCuts.count - 1), id: \.self) { i in
                Rectangle()
                    .fill(red)
                    .frame(width: geo.size.width, height: 2.5)
                    .position(x: geo.size.width/2, y: yCuts[i] * geo.size.height)
            }
        }
    }
}
// MARK: - Short titles

extension WasteKind {
    var titleShortUpper: String {
        switch self {
        case .papir: return "PAPÍR"
        case .plast: return "PLAST"
        case .bioodpad: return "BIO"
        case .sklo: return "SKLO"
        case .textil: return "TEXTIL"
        }
    }
}


#Preview {
    NavigationStack {
        // Do stats pošleme nil (nebo ukázková data),
        // a do onContinue prázdnou closure {}.
        InfoView(stats: nil, onContinue: {
            print("Pokračovat stisknuto")
        })
    }
}
