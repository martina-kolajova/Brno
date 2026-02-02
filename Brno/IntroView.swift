//
//  IntroView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI


struct InfoView: View {
    var onContinue: () -> Void = {}

    @State private var dragX: CGFloat = 0
    @State private var hasTriggered = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {

                Spacer(minLength: 18)

                // MARK: - Header (minimal)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kam s tým?")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.black)

                    Text("Rychle najdeš nejbližší kontejnery na tříděný odpad v Brně.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.black.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // MARK: - Minimal list
                VStack(spacing: 10) {
                    InfoRowMinimal(
                        icon: "mappin.and.ellipse",
                        title: "Najdi stanoviště",
                        subtitle: "Podle polohy a typu odpadu."
                    )
                    InfoRowMinimal(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "Vyber komoditu",
                        subtitle: "Papír, plast, sklo, textil, bio…"
                    )
                    InfoRowMinimal(
                        icon: "hand.raised.fill",
                        title: "Neodhazuj vedle",
                        subtitle: "Když je plno, radši jiné stanoviště."
                    )
                }
                .padding(.top, 6)

                Spacer()

                // MARK: - Swipe hint (use your component)
            
                SwipeHint(
                    direction: .right
                )
                
                
            
                
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)

            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    dragX = max(0, min(140, value.translation.width))
                }
                .onEnded { value in
                    if value.translation.width > 90, !hasTriggered {
                        hasTriggered = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onContinue()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            dragX = 0
                        }
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
    }
}

private struct InfoRowMinimal: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.035))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.black.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.black.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        InfoView(onContinue: {})
    }
}
