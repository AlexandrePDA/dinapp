import CoreData

extension NSManagedObjectContext {
    /// Supprime une escapade et, si elle était la dernière étape
    /// de son séjour, le séjour devenu vide avec.
    func deleteDestination(_ destination: Destination) {
        let trip = destination.trip
        delete(destination)
        deleteIfEmpty(trip, excluding: destination)
        saveLoggingFailure()
    }

    /// Supprime un séjour s'il n'a plus d'étape (en ignorant celle
    /// en cours de suppression ou de réaffectation).
    func deleteIfEmpty(_ trip: Trip?, excluding destination: Destination) {
        guard let trip else { return }
        let remaining = trip.destinationsArray.filter { $0.identifier != destination.identifier }
        if remaining.isEmpty { delete(trip) }
    }

    /// Sauvegarde en loguant l'échec plutôt qu'en l'avalant.
    func saveLoggingFailure() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            AppLog.persistence.error("Échec d'enregistrement Core Data : \(String(describing: error))")
        }
    }
}
