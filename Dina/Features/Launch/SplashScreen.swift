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

    private var decorativeBackground: some View {
        ZStack {
            BlobShape(seed: 0.9)
                .fill(AppColors.peach.opacity(0.30))
                .frame(width: 320, height: 320)
                .offset(x: -140, y: -320)
                .blur(radius: 4)
            BlobShape(seed: 0.7)
                .fill(AppColors.sky.opacity(0.28))
                .frame(width: 280, height: 280)
                .offset(x: 160, y: -240)
                .blur(radius: 4)
            BlobShape(seed: 0.8)
                .fill(AppColors.butter.opacity(0.28))
                .frame(width: 240, height: 240)
                .offset(x: 120, y: 320)
                .blur(radius: 4)
        }
        .ignoresSafeArea()
    }
}
