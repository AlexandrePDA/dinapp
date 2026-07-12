import SwiftUI
import CloudKit
import UIKit

struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let sharingService: SharingService

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.delegate = context.coordinator
        controller.modalPresentationStyle = .formSheet
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(sharingService: sharingService)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let sharingService: SharingService

        init(sharingService: SharingService) {
            self.sharingService = sharingService
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            guard let share = csc.share else { return }
            Task { @MainActor in
                sharingService.persistUpdatedShare(share)
            }
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            guard let share = csc.share else { return }
            Task { @MainActor in
                if share.owner != share.currentUserParticipant {
                    // Participant : quitter le partage retire la copie locale.
                    sharingService.purgeSharedZone(of: share)
                } else {
                    sharingService.persistUpdatedShare(share)
                }
            }
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            AppLog.sharing.error("Échec d'enregistrement du partage : \(String(describing: error))")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Journal de bébé"
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            nil
        }

        func itemType(for csc: UICloudSharingController) -> String? {
            "com.apple.cloudkit.share"
        }
    }
}
