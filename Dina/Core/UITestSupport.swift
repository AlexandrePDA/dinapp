#if DEBUG
import Foundation
import CoreData
import CoreLocation
import UIKit

/// Injection de données pour les tests UI : lancée avec « --uitest-seed »,
/// l'app repart d'un journal contenant une seule escapade connue,
/// avec photos et séjour (le cas réel le plus complet).
@MainActor
enum UITestSupport {
    static func seedIfRequested(context: NSManagedObjectContext, familyManager: FamilyManager) {
        guard ProcessInfo.processInfo.arguments.contains("--uitest-seed") else { return }

        let destinations = (try? context.fetch(NSFetchRequest<Destination>(entityName: "Destination"))) ?? []
        destinations.forEach(context.delete)
        let trips = (try? context.fetch(NSFetchRequest<Trip>(entityName: "Trip"))) ?? []
        trips.forEach(context.delete)

        let family = familyManager.currentFamily(in: context)
        let trip = Trip(context: context, title: "Été en Normandie", startDate: Date().addingTimeInterval(-172_800), family: family)
        let destination = Destination(
            context: context,
            placeName: "Cabourg",
            subtitle: "Normandie, France",
            coordinate: CLLocationCoordinate2D(latitude: 49.286, longitude: -0.115),
            visitDate: Date().addingTimeInterval(-86_400),
            purpose: .weekend,
            notes: "Première fois à la mer.",
            family: family
        )
        destination.trip = trip
        for tint in [UIColor.systemOrange, .systemTeal] {
            _ = DestinationPhoto(context: context, imageData: sampleJPEG(tint: tint), destination: destination)
        }
        context.saveLoggingFailure()
    }

    private static func sampleJPEG(tint: UIColor) -> Data {
        let size = CGSize(width: 600, height: 400)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            tint.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
#endif
