import SwiftUI

struct InfoView: View {
    var stats: KontejnerStats?
    var onContinue: () -> Void
    
    // --- STAVY PRO ANIMACE ---
    @State private var step1Offset: CGFloat = 600
    @State private var step2Offset: CGFloat = 600
    @State private var showStats = false
    @State private var showOrloj = false
    @State private var showNumbers = false
    
    // --- STAV PRO DETAILNÍ KARTU ---
    @State private var selectedCategory: WasteKind? = nil

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                // 1. TEXTOVÁ SEKCE (Příjezd zprava)
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

                // 2. INTERAKTIVNÍ ORLOJ (Výjezd zespodu)
                Group {
                    if showOrloj {
                        OrlojStatsView(stats: stats, showNumbers: showNumbers) { kind in
                            selectedCategory = kind // Otevře sheet
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 500)

                Spacer()
                
                // 3. SWIPE HINT & TLAČÍTKO
                VStack {
                    SwipeHint(direction: .right)
                        .opacity(showNumbers ? 1 : 0)
                    
                    // Neviditelná plocha dole pro zachování layoutu
                    Color.clear.frame(height: 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
        // --- MODÁLNÍ OKNO (DETAILY) ---
        .sheet(item: $selectedCategory) { kind in
            OdpadDetailView(kind: kind, count: stats?.byKind[kind] ?? 0)
                .presentationDetents([.medium]) // iOS 16+
                .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            runFullSequence()
        }
    }

    private func runFullSequence() {
        let driveAnim = Animation.timingCurve(0.15, 0.85, 0.35, 1.0, duration: 2.5)

        withAnimation(driveAnim) { step1Offset = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(driveAnim) { step2Offset = 0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) { showStats = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) { showOrloj = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeIn(duration: 0.8)) { showNumbers = true }
        }
    }
}

// MARK: - DETAILNÍ STRÁNKA (Sheet)
struct OdpadDetailView: View {
    let kind: WasteKind
    let count: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 25) {
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundStyle(.gray.opacity(0.3))
                .padding(.top, 15)

            Text(kind.titleShortUpper)
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(.red)

            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 70, weight: .black, design: .rounded))
                Text("KONTEJNERŮ V CELÉM BRNĚ")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("CO SEM PATŘÍ:")
                    .font(.system(size: 14, weight: .black))
                
                Text(getHint(for: kind))
                    .font(.system(size: 18, weight: .medium))
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(25)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            Spacer()
            
            Button("ZAVŘÍT") { dismiss() }
                .font(.headline)
                .foregroundStyle(.gray)
                .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
    
    func getHint(for kind: WasteKind) -> String {
        switch kind {
        case .plast: return "PET lahve, kelímky, fólie, sáčky, krabice od mléka (tetrapak), polystyren."
        case .papir: return "Časopisy, noviny, papírové krabice, letáky, obálky s fólií."
        case .sklo: return "Nevratné lahve od nápojů, sklenice od zavařenin, tabulové sklo."
        case .bioodpad: return "Zbytky ovoce a zeleniny, kávová sedlina, tráva, listí, plevel."
        case .textil: return "Čisté oblečení, obuv, bytový textil (zavázané v sáčcích)."
        }
    }
}

// MARK: - ORLOJ STATS VIEW
private struct OrlojStatsView: View {
    let stats: KontejnerStats?
    let showNumbers: Bool
    var onSelect: (WasteKind) -> Void
    
    private let order: [WasteKind] = [.papir, .plast, .bioodpad, .sklo, .textil]
    private let yCuts: [CGFloat] = [0.20, 0.36, 0.52, 0.68, 0.84, 0.98]

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width * 0.82, 320)
            let h = geo.size.height

            ZStack {
                OrlojShape()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

                OrlojShape()
                    .stroke(Color.red, lineWidth: 5)

                OrlojInnerLines(yCuts: yCuts, red: .red)
                    .clipShape(OrlojShape())

                if let stats = stats, showNumbers {
                    ForEach(0..<order.count, id: \.self) { i in
                        let midY = (yCuts[i] + yCuts[i+1]) / 2 * h
                        
                        Button(action: { onSelect(order[i]) }) {
                            HStack(spacing: 5) {
                                Text(order[i].titleShortUpper)
                                    .font(.system(size: 15, weight: .black))
                                Text(":")
                                    .font(.system(size: 15, weight: .black))
                                Text("\(stats.byKind[order[i], default: 0])")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.black)
                            .frame(width: w, height: (yCuts[i+1] - yCuts[i]) * h)
                            .contentShape(Rectangle())
                        }
                        .position(x: w / 2, y: midY)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - TVARY A ROZŠÍŘENÍ (Zůstávají stejné)
private struct OrlojShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let topY = h * 0.03
        let bottomY = h * 0.98
        path.move(to: CGPoint(x: w * 0.22, y: bottomY))
        path.addCurve(to: CGPoint(x: w * 0.5, y: topY), control1: CGPoint(x: w * 0.18, y: h * 0.70), control2: CGPoint(x: w * 0.2, y: h * 0.05))
        path.addCurve(to: CGPoint(x: w * 0.78, y: bottomY), control1: CGPoint(x: w * 0.8, y: h * 0.05), control2: CGPoint(x: w * 0.82, y: h * 0.70))
        path.addLine(to: CGPoint(x: w * 0.22, y: bottomY))
        path.closeSubpath()
        return path
    }
}

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

extension WasteKind: Identifiable {
    public var id: String { self.rawValue }
    
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