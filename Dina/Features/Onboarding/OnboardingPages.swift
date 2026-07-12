import SwiftUI

struct OnboardingWelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: AppColors.plum.opacity(0.20), radius: 24, x: 0, y: 18)

            VStack(spacing: 12) {
                Text("Bienvenue")
                    .font(AppTypography.overline)
                    .tracking(2)
                    .foregroundStyle(AppColors.plumSoft)

                VStack(spacing: 2) {
                    Text("Le journal")
                        .font(AppTypography.editorialLarge)
                        .foregroundStyle(AppColors.plum)
                    Text("des petites aventures")
                        .font(AppTypography.editorialLarge)
                        .foregroundStyle(AppColors.peachDeep)
                        .multilineTextAlignment(.center)
                }

                Text("Une trace joyeuse des sorties, week-ends\net vacances de votre bébé.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.plumSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 20)
        }
    }
}

struct OnboardingAddPage: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)

            AddMockup()
                .frame(maxWidth: 320)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Text("Étape 1")
                    .font(AppTypography.overline)
                    .tracking(2)
                    .foregroundStyle(AppColors.peachDeep)

                Text("Marquez chaque escapade")
                    .font(AppTypography.editorial)
                    .foregroundStyle(AppColors.plum)
                    .multilineTextAlignment(.center)

                Text("Trouvez un lieu, choisissez l'occasion\net glissez un souvenir.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.plumSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 20)
        }
    }
}

struct OnboardingMapPage: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)

            MapMockup()
                .frame(width: 300, height: 300)

            VStack(spacing: 10) {
                Text("Étape 2")
                    .font(AppTypography.overline)
                    .tracking(2)
                    .foregroundStyle(AppColors.skyDeep)

                Text("Une carte qui grandit")
                    .font(AppTypography.editorial)
                    .foregroundStyle(AppColors.plum)
                    .multilineTextAlignment(.center)

                Text("Voyez d'un coup d'œil tous les endroits\nque bébé a découverts.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.plumSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 20)
        }
    }
}

struct OnboardingSetupPage: View {
    @Binding var name: String
    @Binding var birthDate: Date

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.butter.opacity(0.7), AppColors.peach.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 10) {
                    Text("Presque prêt")
                        .font(AppTypography.overline)
                        .tracking(2)
                        .foregroundStyle(AppColors.peachDeep)

                    Text("Comment s'appelle-t-il ?")
                        .font(AppTypography.editorial)
                        .foregroundStyle(AppColors.plum)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    fieldGroup(title: "Prénom") {
                        TextField("Ex : Lilou", text: $name)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(AppColors.plum)
                    }

                    fieldGroup(title: "Date de naissance") {
                        DatePicker(
                            "",
                            selection: $birthDate,
                            in: ...Date.now,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .tint(AppColors.peachDeep)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func fieldGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppTypography.overline)
                .tracking(1.4)
                .foregroundStyle(AppColors.plumSoft)
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Capsule().fill(AppColors.sand))
                .overlay(Capsule().strokeBorder(AppColors.peach.opacity(0.3), lineWidth: 1))
        }
    }
}
