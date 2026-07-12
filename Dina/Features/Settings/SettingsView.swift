import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(FamilyManager.self) private var familyManager
    @FetchRequest(sortDescriptors: []) private var babies: FetchedResults<BabyProfile>

    @State private var babyName: String = ""
    @State private var birthDate: Date = .now

    private var scopedBaby: BabyProfile? {
        familyManager.scoped(babies).first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                profileSection
                coParentSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
        .scrollIndicators(.hidden)
        .onAppear(perform: loadProfile)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Réglages")
                .font(AppTypography.editorialLarge)
                .foregroundStyle(AppColors.plum)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileSection: some View {
        SectionCard(title: "Le profil de bébé", systemImage: "person.crop.circle", tint: AppColors.peach) {
            VStack(alignment: .leading, spacing: 12) {
                labeledField(title: "Prénom") {
                    TextField("Ex : Lilou", text: $babyName)
                        .textInputAutocapitalization(.words)
                }
                labeledField(title: "Date de naissance") {
                    DatePicker("", selection: $birthDate, in: ...Date.now, displayedComponents: [.date])
                        .labelsHidden()
                }
                Button(action: saveProfile) {
                    Text("Enregistrer")
                        .font(AppTypography.bodyEmphasized)
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
                        .shadow(color: AppColors.peachDeep.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(babyName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(babyName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
    }

    private var coParentSection: some View {
        SectionCard(title: "Le co-parent", systemImage: "person.2.fill", tint: AppColors.sky) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Invitez l'autre parent à contribuer au journal. Aucun compte à créer, tout passe par iCloud.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.plumSoft)
                ShareTripButton()
            }
        }
    }

    private var aboutSection: some View {
        SectionCard(title: "À propos", systemImage: "info.circle", tint: AppColors.butter) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dinapp")
                            .font(AppTypography.title3)
                            .foregroundStyle(AppColors.plum)
                        Text("Journal des petites aventures")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.plumSoft)
                    }
                    Spacer(minLength: 0)
                }
                Divider().overlay(AppColors.hairline)
                aboutRow(label: "Version", value: appVersion)
                Divider().overlay(AppColors.hairline)
                aboutRow(label: "Confidentialité", value: "iCloud privé")
            }
        }
    }

    private func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppTypography.overline)
                .tracking(1.2)
                .foregroundStyle(AppColors.plumSoft)
            content()
                .foregroundStyle(AppColors.plum)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(AppColors.sand))
                .overlay(Capsule().strokeBorder(AppColors.hairline, lineWidth: 1))
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.plum)
            Spacer()
            Text(value)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.plumSoft)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadProfile() {
        if let existing = scopedBaby {
            babyName = existing.name
            birthDate = existing.birthDate
        }
    }

    private func saveProfile() {
        if let existing = scopedBaby {
            existing.name = babyName
            existing.birthDate = birthDate
        } else {
            let family = familyManager.currentFamily(in: context)
            _ = BabyProfile(context: context, name: babyName, birthDate: birthDate, family: family)
        }
        context.saveLoggingFailure()
    }
}
