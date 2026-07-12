import SwiftUI

struct AddMockup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nouvelle escapade")
                .font(AppTypography.editorialSmall)
                .foregroundStyle(AppColors.plum)

            searchField
            purposeChips
            memoryHint
        }
        .padding(20)
        .background(
            AsymmetricSquircle(topLeading: 34, topTrailing: 22, bottomLeading: 22, bottomTrailing: 34)
                .fill(AppColors.sand)
        )
        .overlay(
            AsymmetricSquircle(topLeading: 34, topTrailing: 22, bottomLeading: 22, bottomTrailing: 34)
                .strokeBorder(AppColors.peach.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: AppColors.plum.opacity(0.12), radius: 20, x: 0, y: 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.skyDeep)
            Text("Cabourg")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.plum)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.sky)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Capsule().fill(AppColors.sky.opacity(0.15)))
    }

    private var purposeChips: some View {
        HStack(spacing: 8) {
            miniChip(icon: "sun.max.fill", label: "Week-end", tint: AppColors.butter, selected: true)
            miniChip(icon: "beach.umbrella.fill", label: "Vacances", tint: AppColors.sky, selected: false)
            miniChip(icon: "sparkles", label: "Balade", tint: AppColors.peachDeep, selected: false)
        }
    }

    private func miniChip(icon: String, label: String, tint: Color, selected: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(label)
                .font(AppTypography.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(selected ? .white : AppColors.plum)
        .background(Capsule().fill(selected ? tint : tint.opacity(0.2)))
    }

    private var memoryHint: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundStyle(AppColors.peachDeep)
            Text("Première fois qu'il voit la mer.")
                .font(AppTypography.footnote)
                .italic()
                .foregroundStyle(AppColors.plum.opacity(0.85))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.peach.opacity(0.15))
        )
    }
}

struct MapMockup: View {
    var body: some View {
        ZStack {
            AsymmetricSquircle(topLeading: 36, topTrailing: 24, bottomLeading: 24, bottomTrailing: 36)
                .fill(
                    LinearGradient(
                        colors: [AppColors.sky.opacity(0.25), AppColors.sand],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            AsymmetricSquircle(topLeading: 36, topTrailing: 24, bottomLeading: 24, bottomTrailing: 36)
                .strokeBorder(AppColors.sky.opacity(0.35), lineWidth: 1)

            landmasses

            routes

            pins
        }
        .shadow(color: AppColors.plum.opacity(0.15), radius: 22, x: 0, y: 12)
    }

    private var landmasses: some View {
        Canvas { context, size in
            let path1 = Path { p in
                p.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.20))
                p.addCurve(
                    to: CGPoint(x: size.width * 0.55, y: size.height * 0.35),
                    control1: CGPoint(x: size.width * 0.30, y: size.height * 0.10),
                    control2: CGPoint(x: size.width * 0.45, y: size.height * 0.20)
                )
                p.addCurve(
                    to: CGPoint(x: size.width * 0.85, y: size.height * 0.55),
                    control1: CGPoint(x: size.width * 0.70, y: size.height * 0.45),
                    control2: CGPoint(x: size.width * 0.85, y: size.height * 0.40)
                )
                p.addCurve(
                    to: CGPoint(x: size.width * 0.55, y: size.height * 0.85),
                    control1: CGPoint(x: size.width * 0.90, y: size.height * 0.75),
                    control2: CGPoint(x: size.width * 0.70, y: size.height * 0.80)
                )
                p.addCurve(
                    to: CGPoint(x: size.width * 0.15, y: size.height * 0.65),
                    control1: CGPoint(x: size.width * 0.35, y: size.height * 0.90),
                    control2: CGPoint(x: size.width * 0.10, y: size.height * 0.80)
                )
                p.closeSubpath()
            }
            context.fill(path1, with: .color(AppColors.butter.opacity(0.35)))
            context.stroke(path1, with: .color(AppColors.butter.opacity(0.6)), lineWidth: 1.5)
        }
        .padding(24)
    }

    private var routes: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.32))
                p.addQuadCurve(
                    to: CGPoint(x: size.width * 0.55, y: size.height * 0.55),
                    control: CGPoint(x: size.width * 0.30, y: size.height * 0.50)
                )
                p.addQuadCurve(
                    to: CGPoint(x: size.width * 0.75, y: size.height * 0.70),
                    control: CGPoint(x: size.width * 0.72, y: size.height * 0.58)
                )
            }
            context.stroke(
                path,
                with: .color(AppColors.peachDeep.opacity(0.55)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
            )
        }
        .padding(24)
    }

    private var pins: some View {
        GeometryReader { geometry in
            let size = geometry.size
            miniPin(icon: "sun.max.fill", tint: AppColors.butter)
                .position(x: size.width * 0.28, y: size.height * 0.32)
            miniPin(icon: "beach.umbrella.fill", tint: AppColors.sky)
                .position(x: size.width * 0.58, y: size.height * 0.55)
            miniPin(icon: "sparkles", tint: AppColors.peachDeep)
                .position(x: size.width * 0.78, y: size.height * 0.72)
        }
    }

    private func miniPin(icon: String, tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 34, height: 34)
            Circle()
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: 34, height: 34)
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .shadow(color: AppColors.plum.opacity(0.35), radius: 6, x: 0, y: 4)
    }
}
