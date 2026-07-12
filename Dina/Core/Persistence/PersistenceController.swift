import Foundation
import CoreData
import CloudKit

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    /// Store miroir de la base CloudKit privée (nos propres données).
    private(set) var privatePersistentStore: NSPersistentStore!
    /// Store miroir de la base CloudKit partagée (le journal reçu du co-parent).
    private(set) var sharedPersistentStore: NSPersistentStore?

    private init() {
        container = NSPersistentCloudKitContainer(name: "Dina", managedObjectModel: DinaModel.shared)

        // Le store privé réutilise l'emplacement de l'ancien store SwiftData :
        // même schéma, mêmes données, même historique de synchronisation.
        let directory = URL.applicationSupportDirectory
        let privateURL = directory.appending(path: "default.store")
        let sharedURL = directory.appending(path: "shared.store")

        let privateDescription = NSPersistentStoreDescription(url: privateURL)
        Self.configure(privateDescription)
        let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: SharingService.containerIdentifier)
        privateOptions.databaseScope = .private
        privateDescription.cloudKitContainerOptions = privateOptions

        let sharedDescription = NSPersistentStoreDescription(url: sharedURL)
        Self.configure(sharedDescription)
        let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: SharingService.containerIdentifier)
        sharedOptions.databaseScope = .shared
        sharedDescription.cloudKitContainerOptions = sharedOptions

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]

        loadStores()

        for store in container.persistentStoreCoordinator.persistentStores {
            switch store.url {
            case privateURL: privatePersistentStore = store
            case sharedURL: sharedPersistentStore = store
            default: break
            }
        }
        if privatePersistentStore == nil {
            privatePersistentStore = container.persistentStoreCoordinator.persistentStores.first
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.transactionAuthor = "app"
        container.viewContext.name = "viewContext"
    }

    private static func configure(_ description: NSPersistentStoreDescription) {
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
    }

    /// Charge les stores ; en cas d'incompatibilité irrécupérable, le store
    /// fautif est détruit puis recréé (les données reviennent ensuite via
    /// CloudKit, dont les types d'enregistrements sont inchangés).
    private func loadStores() {
        var failedURLs: [URL] = []
        container.loadPersistentStores { description, error in
            if let error {
                AppLog.persistence.fault("Échec d'ouverture du store \(description.url?.lastPathComponent ?? "?") : \(String(describing: error))")
                if let url = description.url {
                    failedURLs.append(url)
                }
            }
        }
        guard !failedURLs.isEmpty else { return }

        for url in failedURLs {
            do {
                try container.persistentStoreCoordinator.destroyPersistentStore(at: url, type: .sqlite)
                AppLog.persistence.warning("Store recréé après destruction : \(url.lastPathComponent)")
            } catch {
                fatalError("Impossible de réinitialiser le store : \(error)")
            }
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Impossible d'initialiser la persistance : \(error)")
            }
        }
    }
}
