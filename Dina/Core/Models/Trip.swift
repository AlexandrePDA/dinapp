import Foundation
import CoreData

@objc(Trip)
final class Trip: NSManagedObject, Identifiable {
    @NSManaged var identifier: UUID
    @NSManaged var title: String
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?
    @NSManaged var createdAt: Date

    @NSManaged var family: Family?
    @NSManaged var destinations: NSSet?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }

    convenience init(
        context: NSManagedObjectContext,
        title: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        family: Family? = nil
    ) {
        self.init(context: context)
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.family = family
    }

    var destinationsArray: [Destination] {
        (destinations as? Set<Destination>).map(Array.init) ?? []
    }

    var sortedDestinations: [Destination] {
        destinationsArray.sorted { $0.visitDate < $1.visitDate }
    }

    /// « 1 étape » ou « n étapes ».
    var stepsCountLabel: String {
        let count = destinationsArray.count
        return count <= 1 ? "1 étape" : "\(count) étapes"
    }

    /// « 2 juil. – 15 août », ou la date seule si tout tient sur un jour.
    var dateRangeLabel: String? {
        let dates = sortedDestinations.map(\.visitDate)
        guard let first = dates.first, let last = dates.last else { return nil }
        if Calendar.current.isDate(first, inSameDayAs: last) {
            return first.formatted(.shortDay)
        }
        return "\(first.formatted(.shortDay)) – \(last.formatted(.shortDay))"
    }
}
