import Foundation
import CoreData
import Observation

@MainActor
@Observable
final class FamilyManager {
    private static let currentFamilyIDKey = "com.alexandre.dina.currentFamilyID"

    private(set) var currentFamilyID: UUID?
    /// Vrai entre l'acceptation d'une invitation et l'arrivée de la
    /// famille partagée via la synchronisation CloudKit.
    private(set) var isAwaitingSharedFamily = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: Self.currentFamilyIDKey),
           let uuid = UUID(uuidString: stored) {
            self.currentFamilyID = uuid
        }
    }

    func bootstrap(with context: NSManagedObjectContext) {
        if let currentFamilyID {
            if resolveFamily(id: currentFamilyID, in: context) == nil, !isAwaitingSharedFamily {
                let family = createFamily(in: context)
                update(currentFamilyID: family.identifier)
            }
            return
        }

        if let existing = fetchFirstFamily(in: context) {
            update(currentFamilyID: existing.identifier)
            return
        }

        let family = createFamily(in: context)
        update(currentFamilyID: family.identifier)
    }

    /// Après acceptation d'une invitation : bascule sur la famille partagée
    /// dès qu'elle est présente, sinon attend la fin de l'import CloudKit
    /// (voir `adoptSharedFamilyIfNeeded`, appelé sur les remote changes).
    func adoptSharedFamily(context: NSManagedObjectContext) {
        isAwaitingSharedFamily = true
        adoptSharedFamilyIfNeeded(context: context)
    }

    func adoptSharedFamilyIfNeeded(context: NSManagedObjectContext) {
        guard isAwaitingSharedFamily else { return }
        guard let shared = fetchSharedFamily(in: context) else { return }
        isAwaitingSharedFamily = false
        update(currentFamilyID: shared.identifier)
    }

    func currentFamily(in context: NSManagedObjectContext) -> Family? {
        guard let currentFamilyID else { return nil }
        return resolveFamily(id: currentFamilyID, in: context)
    }

    private func resolveFamily(id: UUID, in context: NSManagedObjectContext) -> Family? {
        let request = Family.typedFetchRequest()
        request.predicate = NSPredicate(format: "identifier == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func fetchFirstFamily(in context: NSManagedObjectContext) -> Family? {
        let request = Family.typedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    /// La famille présente dans le store partagé (celle du co-parent).
    private func fetchSharedFamily(in context: NSManagedObjectContext) -> Family? {
        guard let sharedStore = PersistenceController.shared.sharedPersistentStore else { return nil }
        let request = Family.typedFetchRequest()
        request.affectedStores = [sharedStore]
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func createFamily(in context: NSManagedObjectContext) -> Family {
        let family = Family(context: context, title: "Ma famille")
        context.saveLoggingFailure()
        return family
    }

    private func update(currentFamilyID id: UUID) {
        currentFamilyID = id
        defaults.set(id.uuidString, forKey: Self.currentFamilyIDKey)
    }

    /// Restreint une collection d'objets à la famille active ; sans famille
    /// active, tout est conservé (premier lancement, avant `bootstrap`).
    func scoped<S: Sequence>(_ items: S) -> [S.Element] where S.Element: FamilyOwned {
        guard let currentFamilyID else { return Array(items) }
        return items.filter { $0.family?.identifier == currentFamilyID }
    }
}

/// Objet rattaché à une famille, filtrable via `FamilyManager.scoped(_:)`.
protocol FamilyOwned {
    var family: Family? { get }
}

extension Destination: FamilyOwned {}
extension Trip: FamilyOwned {}
extension BabyProfile: FamilyOwned {}
