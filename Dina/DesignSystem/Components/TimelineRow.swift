import SwiftUI

struct TimelineRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.30))
                    Circle()
                        .strokeBorder(tint, lineWidth: 2)
                    Image(systemName: systemImage)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppColors.plum)
                }
                .frame(width: 32, height: 32)

                if !isLast {
                    Rectangle()
                        .fill(AppColors.plum.opacity(0.15))
                        .frame(width: 2)
                        .frame(minHeight: 32)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.plum)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .tracking(0.6)
                    .foregroundStyle(AppColors.plumSoft)
            }
            .padding(.top, 4)
            Spacer(minLength: 0)
        }
    }
}
