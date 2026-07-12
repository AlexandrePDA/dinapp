import Foundation
import CoreData
import CloudKit
import SwiftUI

/// Partage du journal familial via NSPersistentCloudKitContainer :
/// on partage l'objet Family — Core Data déplace tout son graphe
/// (sorties, photos, séjours, profil) dans une zone partagée CloudKit.
@MainActor
final class SharingService: ObservableObject {
    nonisolated static let containerIdentifier = "iCloud.com.alexandre.dina"

    @Published private(set) var accountAvailable: Bool = false

    let container: CKContainer
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        self.container = CKContainer(identifier: Self.containerIdentifier)
    }

    func refreshAccountStatus() async {
        accountAvailable = (try? await container.accountStatus()) == .available
    }

    /// Retourne le partage existant de la famille, ou le crée.
    func makeShare(for family: Family) async throws -> (CKShare, CKContainer) {
        if let existing = try existingShare(for: family) {
            return (existing, container)
        }
        let (_, share, _) = try await persistence.container.share([family], to: nil)
        share[CKShare.SystemFieldKey.title] = "Journal de bébé" as CKRecordValue
        let persisted = try await persistence.container.persistUpdatedShare(share, in: persistence.privatePersistentStore)
        return (persisted, container)
    }

    private func existingShare(for family: Family) throws -> CKShare? {
        let shares = try persistence.container.fetchShares(matching: [family.objectID])
        return shares[family.objectID]
    }

    /// Sauvegarde côté Core Data les modifications faites au partage
    /// dans UICloudSharingController (participants, permissions…).
    func persistUpdatedShare(_ share: CKShare) {
        Task {
            do {
                _ = try await persistence.container.persistUpdatedShare(share, in: persistence.privatePersistentStore)
            } catch {
                AppLog.sharing.error("Échec de persistance du partage : \(String(describing: error))")
            }
        }
    }

    /// Côté participant : quitter le partage supprime la copie locale
    /// de la zone partagée.
    func purgeSharedZone(of share: CKShare) {
        guard let sharedStore = persistence.sharedPersistentStore else { return }
        Task {
            do {
                _ = try await persistence.container.purgeObjectsAndRecordsInZone(
                    with: share.recordID.zoneID,
                    in: sharedStore
                )
            } catch {
                AppLog.sharing.error("Échec de purge de la zone partagée : \(String(describing: error))")
            }
        }
    }
}
