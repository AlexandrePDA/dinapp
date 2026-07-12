import Foundation
import CoreData

@objc(BabyProfile)
final class BabyProfile: NSManagedObject, Identifiable {
    @NSManaged var identifier: UUID
    @NSManaged var name: String
    @NSManaged var birthDate: Date
    @NSManaged var createdAt: Date

    @NSManaged var family: Family?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }

    convenience init(context: NSManagedObjectContext, name: String = "", birthDate: Date = Date(), family: Family? = nil) {
        self.init(context: context)
        self.name = name
        self.birthDate = birthDate
        self.family = family
    }
}
