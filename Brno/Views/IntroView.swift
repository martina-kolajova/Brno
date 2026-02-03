//
//  IntroView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI

// MARK: - InfoView

struct InfoView: View {
    var onContinue: () -> Void = {}

    @State private var hasTriggered = false
    @State private var stats: KontejnerStats? = nil
    @State private var isLoading = false

    private let service = KontejneryService()

    var body: some View {
        GeometryReader { geo in
            let topSafe = geo.safeAreaInsets.top
            let bottomSafe = geo.safeAreaInsets.bottom

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {

                    // MARK: - HERO
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Brno, Brno")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.black)

                        Text("kontejnerů plno.")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.red)
                            .padding(.top, -2)

                        HStack(spacing: 8) {
                            if isLoading {
                                Text("Načítám počty…")
                            } else if let stats {
                                Text("Celkem \(stats.totalContainers) kontejnerů")
                                Text("• \(stats.totalStations) stanovišť")
                            } else {
                                Text("Počty se nepodařilo načíst.")
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.top, 6)
                    }

                    // MARK: - CLOCK
                    Group {
                        if let stats {
                            ClockStatsView(stats: stats)
                                .padding(.top, -2)
                        } else {
                            ClockStatsSkeleton()
                                .padding(.top, -2)
                        }
                    }

                    Spacer(minLength: 12)

                    SwipeHint(direction: .right)
                        .frame(maxWidth: .infinity)
                        .opacity(0.9)
                }
                .padding(.top, topSafe + 8)
                .padding(.horizontal, 22)
                .padding(.bottom, bottomSafe + 10)
            }
        }
        .task { await loadStats() }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width > 90, !hasTriggered {
                        hasTriggered = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onContinue()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
    }

    @MainActor
    private func loadStats() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            stats = try await service.fetchStats()
        } catch {
            stats = nil
            print("fetchStats error:", error)
        }
    }
}

//
// MARK: - ClockStatsView (MENŠÍ + ŘÁDKY PODLE TVARU)
//

private struct ClockStatsView: View {
    let stats: KontejnerStats

    private let order: [WasteKind] = [
        .papir, .plast, .bioodpad, .sklo, .textil
    ]

    // clock.png aspect (518 × 1024)
    private let aspect: CGFloat = 518.0 / 1024.0

    // vertikální řezy podle reálného obrázku
    private let yCuts: [CGFloat] = [
        0.0537, 0.2861, 0.4209, 0.5781, 0.7578, 0.9512
    ]

    // šířka řádku – nahoře hodně úzké
    private let rowWidthFactors: [CGFloat] = [
        0.2, // PAPÍR
        0.32, // PLAST
        0.34, // BIO
        0.36, // SKLO
        0.38  // TEXTIL
    ]

    var body: some View {
        GeometryReader { geo in
            let clockWidth  = min(geo.size.width * 0.9, 280)
            let clockHeight = clockWidth / aspect

            let overlayTop = yCuts.first! * clockHeight

            ZStack {
                Image("clock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: clockWidth, height: clockHeight)

                VStack(spacing: 0) {
                    ForEach(0..<order.count, id: \.self) { i in
                        let rowH = (yCuts[i + 1] - yCuts[i]) * clockHeight
                        let rowW = clockWidth * rowWidthFactors[i]

                        ClockRowCell(
                            title: order[i].titleShortUpper,
                            value: stats.byKind[order[i], default: 0],
                            rowWidth: rowW
                        )
                        .frame(height: rowH)
                    }
                }
                .offset(y: overlayTop)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: (min(UIScreen.main.bounds.width * 0.85, 260) / aspect))
    }
}

//
// MARK: - ClockRowCell (BEZ SPACERU → BLÍZKO)
//

private struct ClockRowCell: View {
    let title: String
    let value: Int
    let rowWidth: CGFloat

    var body: some View {
        HStack(spacing: 6) {

            // LEFT COLUMN (title)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 64, alignment: .leading)   // ⬅️ MIN WIDTH
                .lineLimit(1)                            // ⬅️ NESMÍ SE LÁMAT

            // RIGHT COLUMN (value)
            Text("\(value)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 44, alignment: .trailing)
        }
        // řádek může být úzký, ale text má minimum
        .frame(width: max(rowWidth, 44 + 40 + 6), alignment: .leading)

    }
}


//
// MARK: - Skeleton
//

private struct ClockStatsSkeleton: View {
    private let aspect: CGFloat = 518.0 / 1024.0

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width * 0.85, 260)
            let h = w / aspect

            Image("clock")
                .resizable()
                .scaledToFit()
                .opacity(0.18)
                .frame(width: w, height: h)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: (min(UIScreen.main.bounds.width * 0.85, 260) / aspect))
    }
}

//
// MARK: - Short titles
//

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
        InfoView(onContinue: {})
    }
}
