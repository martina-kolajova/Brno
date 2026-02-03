//
//  IntroView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//
import SwiftUI

struct InfoView: View {
    var onContinue: () -> Void = {}
    @State private var stats: KontejnerStats? = nil
    private let service = KontejneryService()

    var body: some View {
        ZStack { // ZStack pro sjednocení vrstev
            Color.white.ignoresSafeArea()
            
            // 1. VRSTVA: Obsah (Hero + Orloj)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brno, Brno")
                        .font(.system(size: 34, weight: .bold))
                    Text("kontejnerů plno.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.red)

                    if let stats = stats {
                        Text("Celkem \(stats.totalContainers) kontejnerů • \(stats.totalStations) stanovišť")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.gray)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20) // Přizpůsob si podle potřeby

                Spacer()

                Group {
                    if let stats = stats {
                        OrlojStatsView(stats: stats)
                    } else {
                        ProgressView().tint(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 500)

                Spacer()
                
                // Necháme dole prázdné místo pro SwipeHint, aby do něj orloj nezasahoval
                Color.clear.frame(height: 80)
            }
            
            // 2. VRSTVA: SwipeHint (Stejná úroveň jako v "Bordel" view)
            VStack {
                Spacer()
                SwipeHint(direction: .right)
                    .padding(.bottom, 36) // Identické odsazení jako u Bordel view
            }
        }
        .task {
            stats = try? await service.fetchStats()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - OrlojStatsView (Linky vytažené nahoru)
private struct OrlojStatsView: View {
    let stats: KontejnerStats
    private let order: [WasteKind] = [.papir, .plast, .bioodpad, .sklo, .textil]
    
    // Linky začínají na 20% výšky (vysoko v "korku")
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

                OrlojRows(stats: stats, order: order, yCuts: yCuts)
                    .clipShape(OrlojShape())
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


// MARK: - Preview

#Preview {
    NavigationStack {
        InfoView(onContinue: {})
    }
}


