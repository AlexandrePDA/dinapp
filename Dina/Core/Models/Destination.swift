import Foundation
import CoreData
import CoreLocation

@objc(Destination)
final class Destination: NSManagedObject, Identifiable {
    @NSManaged var identifier: UUID
    @NSManaged var placeName: String
    @NSManaged var subtitle: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var visitDate: Date
    @NSManaged var departureDate: Date?
    @NSManaged var purposeRaw: String
    @NSManaged var notes: String
    @NSManaged var createdAt: Date

    @NSManaged var trip: Trip?
    @NSManaged var family: Family?
    @NSManaged var photos: NSSet?

    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
        visitDate = Date()
    }

    convenience init(
        context: NSManagedObjectContext,
        placeName: String = "",
        subtitle: String = "",
        coordinate: CLLocationCoordinate2D = .init(latitude: 0, longitude: 0),
        visitDate: Date = Date(),
        departureDate: Date? = nil,
        purpose: TripPurpose = .weekend,
        notes: String = "",
        family: Family? = nil
    ) {
        self.init(context: context)
        self.placeName = placeName
        self.subtitle = subtitle
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.visitDate = visitDate
        self.departureDate = departureDate
        self.purposeRaw = purpose.rawValue
        self.notes = notes
        self.family = family
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var purpose: TripPurpose {
        TripPurpose(rawValue: purposeRaw) ?? .other
    }

    var sortedPhotos: [DestinationPhoto] {
        ((photos as? Set<DestinationPhoto>).map(Array.init) ?? [])
            .sorted { $0.createdAt < $1.createdAt }
    }
}
