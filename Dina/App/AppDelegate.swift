import UIKit
import CloudKit
import CoreData

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Fournit un scene delegate : dans une app à scènes, l'acceptation
    /// d'une invitation CloudKit arrive sur `UIWindowSceneDelegate`,
    /// jamais sur `UIApplicationDelegate`.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        ShareAcceptanceHandler.accept(cloudKitShareMetadata)
    }
}

@MainActor
enum ShareAcceptanceHandler {
    static func accept(_ metadata: CKShare.Metadata) {
        Task {
            let persistence = PersistenceController.shared
            guard let sharedStore = persistence.sharedPersistentStore else {
                AppLog.sharing.error("Invitation reçue mais store partagé indisponible")
                return
            }
            do {
                try await persistence.container.acceptShareInvitations(from: [metadata], into: sharedStore)
                NotificationCenter.default.post(name: .sharingAccepted, object: nil)
            } catch {
                AppLog.sharing.error("Échec d'acceptation du partage : \(String(describing: error))")
            }
        }
    }
}

extension Notification.Name {
    static let sharingAccepted = Notification.Name("com.alexandre.dina.sharingAccepted")
}
