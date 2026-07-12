import SwiftUI

struct HeroBlob: View {
    let title: String
    let subtitle: String
    let greeting: String
    let ctaLabel: String
    let onCTA: () -> Void

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 6) {
                Text(greeting.uppercased())
                    .font(AppTypography.overline)
                    .tracking(1.8)
                    .foregroundStyle(AppColors.plumSoft.opacity(0.9))

                Text(title)
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.plum)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.plumSoft)
                    .padding(.top, 6)

                Button(action: onCTA) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.callout.weight(.semibold))
                        Text(ctaLabel)
                            .font(AppTypography.bodyEmphasized)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [AppColors.peach, AppColors.peachDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: AppColors.peachDeep.opacity(0.35), radius: 14, x: 0, y: 8)
                }
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }

    private var backgroundLayer: some View {
        ZStack {
            AsymmetricSquircle(
                topLeading: 42,
                topTrailing: 32,
                bottomLeading: 56,
                bottomTrailing: 38
            )
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.peach.opacity(0.55),
                        AppColors.butter.opacity(0.45),
                        AppColors.sky.opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            BlobShape(seed: 0.9)
                .fill(AppColors.butter.opacity(0.55))
                .frame(width: 180, height: 180)
                .offset(x: 100, y: -80)
                .blur(radius: 6)

            BlobShape(seed: 0.7)
                .fill(AppColors.sky.opacity(0.45))
                .frame(width: 160, height: 160)
                .offset(x: -110, y: 90)
                .blur(radius: 8)

            AsymmetricSquircle(
                topLeading: 42,
                topTrailing: 32,
                bottomLeading: 56,
                bottomTrailing: 38
            )
            .fill(.clear)
            .glassEffect(
                .regular.tint(AppColors.peach.opacity(0.05)),
                in: AsymmetricSquircle(
                    topLeading: 42,
                    topTrailing: 32,
                    bottomLeading: 56,
                    bottomTrailing: 38
                )
            )
        }
        .clipShape(
            AsymmetricSquircle(
                topLeading: 42,
                topTrailing: 32,
                bottomLeading: 56,
                bottomTrailing: 38
            )
        )
    }
}
