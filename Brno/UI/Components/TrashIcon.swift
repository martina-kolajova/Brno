//
//  TrashCanView.swift
//  Wasted Brno
//
//  Created by Martina Kolajová on 04.03.2026.
//


// MARK: - Custom Trash Can

/// A hand-drawn trash can made of two parts:
/// - Body: rounded rectangle with vertical line details
/// - Lid: sits on top, pivots open from the right edge when `lidAngle` changes
struct TrashCanView: View {
    var lidAngle: Double   // 0 = closed, negative = open to the left
    var color: Color

    var body: some View {
        ZStack(alignment: .top) {

            // ── Body ──
            VStack(spacing: 0) {
                Spacer().frame(height: 18) // room for the lid

                ZStack {
                    // Bin shape — slightly narrower at the bottom
                    UnevenRoundedRectangle(
                        topLeadingRadius: 3,
                        bottomLeadingRadius: 10,
                        bottomTrailingRadius: 10,
                        topTrailingRadius: 3
                    )
                    .fill(color)
                    .frame(width: 68, height: 82)

                    // Three vertical decorative lines
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 3, height: 55)
                        }
                    }
                }
            }

            // ── Lid (sits flush on top of the body) ──
            VStack(spacing: 0) {
                // Small handle on top of the lid
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 20, height: 8)
                    .offset(y: 2)

                // Lid bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 76, height: 11)
            }
            // Pivot from the left edge — when the can tips left,
            // the lid swings open away from the body (like gravity pulling it)
            .rotationEffect(.degrees(lidAngle), anchor: .leading)
        }
        .frame(width: 84, height: 105)
    }
}