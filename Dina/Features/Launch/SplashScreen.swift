import SwiftUI

/// Écran de démarrage : fond sable et blobs de la palette, icône de
/// l'app au centre, « Dinapp » dans la font éditoriale et sous-titre.
struct SplashScreen: View {
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            decorativeBackground

            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: AppColors.plum.opacity(0.18), radius: 22, x: 0, y: 14)

                VStack(spacing: 6) {
                    Text("Dinapp")
                        .font(AppTypography.editorialLarge)
                        .foregroundStyle(AppColors.plum)
                    Text("Le journal des petites aventures")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.plumSoft)
                }
            }
            .scaleEffect(isRevealed ? 1 : 0.92)
            .opacity(isRevealed ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.2)) {
                isRevealed = true
            }
        }
    }

    /// Même recette que la carte héro de l'accueil, à l'échelle de
    /// l'écran : lavis dégradé pêche → beurre → ciel et blobs très
    /// floutés qui se fondent les uns dans les autres.
    private var decorativeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.peach.opacity(0.55),
                    AppColors.butter.opacity(0.45),
                    AppColors.sky.opacity(0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            BlobShape(seed: 0.9)
                .fill(AppColors.butter.opacity(0.55))
                .frame(width: 430, height: 430)
                .offset(x: 150, y: -280)
                .blur(radius: 42)

            BlobShape(seed: 0.7)
                .fill(AppColors.sky.opacity(0.45))
                .frame(width: 390, height: 390)
                .offset(x: -170, y: 260)
                .blur(radius: 46)

            BlobShape(seed: 0.8)
                .fill(AppColors.peach.opacity(0.45))
                .frame(width: 340, height: 340)
                .offset(x: 130, y: 420)
                .blur(radius: 50)
        }
        .ignoresSafeArea()
    }
}
