import SwiftUI

struct PurposeChip: View {
    let purpose: TripPurpose
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: purpose.systemImage)
                .font(.footnote.weight(.semibold))
            Text(purpose.label)
                .font(AppTypography.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundStyle(isSelected ? .white : AppColors.plum)
        .background(
            Capsule().fill(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [AppColors.tint(for: purpose), AppColors.tint(for: purpose).opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(AppColors.softTint(for: purpose))
            )
        )
        .overlay(
            Capsule().strokeBorder(
                AppColors.tint(for: purpose).opacity(isSelected ? 0 : 0.35),
                lineWidth: 1
            )
        )
        .shadow(
            color: isSelected ? AppColors.tint(for: purpose).opacity(0.35) : .clear,
            radius: 10,
            x: 0,
            y: 6
        )
    }
}
