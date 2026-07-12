import Foundation
import CoreLocation
import MapKit
import CoreData

@MainActor
@Observable
final class AddDestinationViewModel {
    var placeName: String = ""
    var subtitle: String = ""
    var coordinate: CLLocationCoordinate2D?
    var visitDate: Date = .now
    var hasDeparture: Bool = false
    var departureDate: Date = .now.addingTimeInterval(3600 * 24)
    var purpose: TripPurpose = .weekend
    var notes: String = ""
    var photoData: [Data] = []
    var selectedTrip: Trip?
    var isCreatingTrip: Bool = false
    var newTripTitle: String = ""

    var canSave: Bool {
        !placeName.trimmingCharacters(in: .whitespaces).isEmpty && coordinate != nil
    }

    func apply(mapItem: MKMapItem) {
        placeName = mapItem.name ?? placeName
        subtitle = mapItem.placemark.title ?? ""
        coordinate = mapItem.placemark.coordinate
    }

    func makeDestination(in context: NSManagedObjectContext, family: Family?) -> Destination? {
        guard let coordinate else { return nil }
        return Destination(
            context: context,
            placeName: placeName.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle,
            coordinate: coordinate,
            visitDate: visitDate,
            departureDate: hasDeparture ? departureDate : nil,
            purpose: purpose,
            notes: notes.trimmingCharacters(in: .whitespaces),
            family: family
        )
    }

    func load(from destination: Destination) {
        placeName = destination.placeName
        subtitle = destination.subtitle
        coordinate = destination.coordinate
        visitDate = destination.visitDate
        hasDeparture = destination.departureDate != nil
        if let departure = destination.departureDate {
            departureDate = departure
        }
        purpose = destination.purpose
        notes = destination.notes
        selectedTrip = destination.trip
    }

    func update(_ destination: Destination, in context: NSManagedObjectContext, family: Family?) throws {
        guard let coordinate else { return }
        let previousTrip = destination.trip
        destination.placeName = placeName.trimmingCharacters(in: .whitespaces)
        destination.subtitle = subtitle
        destination.latitude = coordinate.latitude
        destination.longitude = coordinate.longitude
        destination.visitDate = visitDate
        destination.departureDate = hasDeparture ? departureDate : nil
        destination.purposeRaw = purpose.rawValue
        destination.notes = notes.trimmingCharacters(in: .whitespaces)
        destination.trip = resolveTrip(in: context, family: family)
        if let previousTrip, previousTrip.identifier != destination.trip?.identifier {
            context.deleteIfEmpty(previousTrip, excluding: destination)
        }
        try context.save()
    }

    func save(into context: NSManagedObjectContext, family: Family?) throws {
        guard let destination = makeDestination(in: context, family: family) else { return }
        destination.trip = resolveTrip(in: context, family: family)
        for data in photoData {
            _ = DestinationPhoto(context: context, imageData: data, destination: destination)
        }
        try context.save()
    }

    private func resolveTrip(in context: NSManagedObjectContext, family: Family?) -> Trip? {
        guard isCreatingTrip else { return selectedTrip }
        let title = newTripTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }
        return Trip(context: context, title: title, startDate: visitDate, family: family)
    }
}
