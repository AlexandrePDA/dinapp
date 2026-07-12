import SwiftUI
import CoreData

struct OnboardingContainer: View {
    @AppStorage("dina.hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.managedObjectContext) private var context
    @Environment(FamilyManager.self) private var familyManager

    @State private var pageIndex: Int = 0
    @State private var babyName: String = ""
    @State private var birthDate: Date = .now

    private let totalPages = 4

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            decorativeBackground

            VStack(spacing: 0) {
                skipButton

                TabView(selection: $pageIndex) {
                    OnboardingWelcomePage()
                        .tag(0)
                    OnboardingAddPage()
                        .tag(1)
                    OnboardingMapPage()
                        .tag(2)
                    OnboardingSetupPage(name: $babyName, birthDate: $birthDate)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smooth, value: pageIndex)

                footer
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

    private var skipButton: some View {
        HStack {
            Spacer()
            if pageIndex < totalPages - 1 {
                Button {
                    withAnimation { pageIndex = totalPages - 1 }
                } label: {
                    Text("Passer")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.plumSoft)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassChip()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 44)
    }

    private var footer: some View {
        VStack(spacing: 18) {
            pageIndicator

            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Text(pageIndex == totalPages - 1 ? "Commencer l'aventure" : "Suivant")
                        .font(AppTypography.bodyEmphasized)
                    Image(systemName: pageIndex == totalPages - 1 ? "sparkles" : "arrow.right")
                        .font(.callout.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
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
                .opacity(canProceed ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!canProceed)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? AppColors.peachDeep : AppColors.plumSoft.opacity(0.3))
                    .frame(width: index == pageIndex ? 24 : 8, height: 8)
                    .animation(.smooth, value: pageIndex)
            }
        }
    }

    private var canProceed: Bool {
        guard pageIndex == totalPages - 1 else { return true }
        return !babyName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func primaryAction() {
        if pageIndex < totalPages - 1 {
            withAnimation { pageIndex += 1 }
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        familyManager.bootstrap(with: context)
        let family = familyManager.currentFamily(in: context)
        let trimmedName = babyName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            _ = BabyProfile(context: context, name: trimmedName, birthDate: birthDate, family: family)
            context.saveLoggingFailure()
        }
        withAnimation(.smooth) { hasOnboarded = true }
    }
}
