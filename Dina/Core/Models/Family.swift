import Foundation
import CoreData

@objc(Family)
final class Family: NSManagedObject, Identifiable {
    @NSManaged var identifier: UUID
    @NSManaged var title: String
    @NSManaged var createdAt: Date

    @NSManaged var babies: NSSet?
    @NSManaged var trips: NSSet?
    @NSManaged var destinations: NSSet?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }

    convenience init(context: NSManagedObjectContext, identifier: UUID = UUID(), title: String = "Ma famille") {
        self.init(context: context)
        self.identifier = identifier
        self.title = title
    }

    static func typedFetchRequest() -> NSFetchRequest<Family> {
        NSFetchRequest<Family>(entityName: "Family")
    }
}
