import Foundation
import CoreData

@objc(DestinationPhoto)
final class DestinationPhoto: NSManagedObject, Identifiable {
    @NSManaged var identifier: UUID
    @NSManaged var imageData: Data
    @NSManaged var createdAt: Date

    @NSManaged var destination: Destination?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }

    convenience init(context: NSManagedObjectContext, imageData: Data, destination: Destination? = nil) {
        self.init(context: context)
        self.imageData = imageData
        self.destination = destination
    }
}
