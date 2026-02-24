import SwiftUI

struct FilterChip: View {
    let filter: KomoditaFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 11, weight: .semibold))

                Text(filter.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.red : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(6)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
