import SwiftUI

// MARK: - DETAILNÍ KARTA
struct OdpadDetailView: View {
    let kind: WasteKind
    let count: Int
    let hint: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 25) {
            Capsule().frame(width: 40, height: 6).foregroundStyle(.gray.opacity(0.3)).padding(.top, 15)
            Text(kind.titleShortUpper).font(.system(size: 38, weight: .black)).foregroundStyle(.red)
            
            VStack(spacing: 0) {
                Text("\(count)").font(.system(size: 70, weight: .black, design: .rounded))
                Text("KONTEJNERŮ V CELÉM BRNĚ").font(.caption.bold()).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("CO SEM PATŘÍ:").font(.system(size: 14, weight: .black))
                Text(hint).font(.system(size: 18, weight: .medium)).lineSpacing(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(25)
            .background(Color.gray.opacity(0.1)).cornerRadius(20)

            Spacer()
            Button("ZAVŘÍT") { dismiss() }.font(.headline).foregroundStyle(.gray).padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

// MARK: - ORLOJ KOMPONENTA
struct OrlojStatsView: View {
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
                OrlojShape().fill(.white).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                OrlojShape().stroke(Color.red, lineWidth: 5)
                OrlojInnerLines(yCuts: yCuts, red: .red).clipShape(OrlojShape())

                if let stats = stats, showNumbers {
                    ForEach(0..<order.count, id: \.self) { i in
                        let midY = (yCuts[i] + yCuts[i+1]) / 2 * h
                        Button(action: { onSelect(order[i]) }) {
                            HStack(spacing: 5) {
                                Text(order[i].titleShortUpper).font(.system(size: 15, weight: .black))
                                Text(":").font(.system(size: 15, weight: .black))
                                Text("\(stats.byKind[order[i], default: 0])").font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.black).frame(width: w, height: (yCuts[i+1] - yCuts[i]) * h).contentShape(Rectangle())
                        }.position(x: w / 2, y: midY)
                    }
                }
            }
            .frame(width: w, height: h).frame(maxWidth: .infinity)
        }
    }
}

// Sem přidej i OrlojShape a OrlojInnerLines, které už máš hotové...