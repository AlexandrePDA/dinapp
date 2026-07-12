import SwiftUI
import CloudKit

struct ShareTripButton: View {
    @Environment(FamilyManager.self) private var familyManager
    @Environment(\.managedObjectContext) private var context
    @StateObject private var sharing = SharingService()
    @State private var presentation: SharePresentation?
    @State private var isPreparing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: prepare) {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.callout.weight(.semibold))
                    Text("Inviter le co-parent")
                        .font(AppTypography.bodyEmphasized)
                    Spacer(minLength: 0)
                    if isPreparing {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [AppColors.sky, AppColors.skyDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: AppColors.skyDeep.opacity(0.3), radius: 10, x: 0, y: 6)
                .opacity(sharing.accountAvailable ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!sharing.accountAvailable || isPreparing)

            if !sharing.accountAvailable {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "icloud.slash")
                        .font(.caption)
                        .foregroundStyle(AppColors.plumSoft)
                    Text("Connectez-vous à iCloud dans les Réglages iOS pour activer le partage.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.plumSoft)
                }
            }
        }
        .task {
            await sharing.refreshAccountStatus()
        }
        .sheet(item: $presentation) { presentation in
            CloudSharingSheet(
                share: presentation.share,
                container: presentation.container,
                sharingService: sharing
            )
            .ignoresSafeArea()
        }
        .alert("Partage impossible", isPresented: errorBinding, actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func prepare() {
        guard !isPreparing else { return }
        guard let family = familyManager.currentFamily(in: context) else {
            errorMessage = "Aucune famille active."
            return
        }
        isPreparing = true
        Task {
            defer { isPreparing = false }
            do {
                let (share, container) = try await sharing.makeShare(for: family)
                presentation = SharePresentation(share: share, container: container)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct SharePresentation: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}
