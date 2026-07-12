import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String?
    let tint: Color
    let content: Content

    init(
        title: String,
        systemImage: String? = nil,
        tint: Color = AppColors.sky,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if let systemImage {
                    ZStack {
                        Circle().fill(tint.opacity(0.35))
                        Image(systemName: systemImage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppColors.plum)
                    }
                    .frame(width: 30, height: 30)
                }
                Text(title)
                    .font(AppTypography.editorialSmall)
                    .foregroundStyle(AppColors.plum)
                Spacer(minLength: 0)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            AsymmetricSquircle(topLeading: 34, topTrailing: 22, bottomLeading: 22, bottomTrailing: 34)
                .fill(tint.opacity(0.14))
        )
        .overlay(
            AsymmetricSquircle(topLeading: 34, topTrailing: 22, bottomLeading: 22, bottomTrailing: 34)
                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
        )
    }
}
