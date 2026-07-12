import SwiftUI

struct CircleStat: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.35))
            Circle()
                .strokeBorder(tint.opacity(0.5), lineWidth: 1)
                .glassEffect(.regular.tint(tint.opacity(0.15)), in: .circle)

            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.plum)
                Text(value)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.plum)
                Text(label)
                    .font(AppTypography.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.plumSoft)
                    .lineLimit(1)
            }
            .padding(6)
        }
        .frame(width: 120, height: 120)
    }
}

struct PillStat: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.4))
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.plum)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.plum)
                Text(label)
                    .font(AppTypography.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.plumSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(tint.opacity(0.18))
                .overlay(
                    Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1)
                )
        )
    }
}
