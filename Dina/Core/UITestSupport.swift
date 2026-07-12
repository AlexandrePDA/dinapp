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
        if ProcessInfo.processInfo.arguments.contains("--uitest-screenshots") {
            seedScreenshotDataset(context: context, familyManager: familyManager)
            return
        }
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

    /// Jeu de données des captures marketing : bébé « Dina », un souvenir
    /// « il y a un an » en Thaïlande et deux escapades à venir.
    private static func seedScreenshotDataset(context: NSManagedObjectContext, familyManager: FamilyManager) {
        let destinations = (try? context.fetch(NSFetchRequest<Destination>(entityName: "Destination"))) ?? []
        destinations.forEach(context.delete)
        let trips = (try? context.fetch(NSFetchRequest<Trip>(entityName: "Trip"))) ?? []
        trips.forEach(context.delete)
        let babies = (try? context.fetch(NSFetchRequest<BabyProfile>(entityName: "BabyProfile"))) ?? []
        babies.forEach(context.delete)

        let family = familyManager.currentFamily(in: context)
        let calendar = Calendar.current

        _ = BabyProfile(
            context: context,
            name: "Dina",
            birthDate: calendar.date(from: DateComponents(year: 2025, month: 3, day: 14)) ?? .now,
            family: family
        )

        let thailand = Destination(
            context: context,
            placeName: "Thaïlande",
            subtitle: "Îles Similan, Thaïlande",
            coordinate: CLLocationCoordinate2D(latitude: 8.653, longitude: 97.645),
            visitDate: calendar.date(byAdding: .year, value: -1, to: .now) ?? .now,
            purpose: .vacation,
            notes: "Premier voyage de Dina",
            family: family
        )
        _ = DestinationPhoto(context: context, imageData: beachJPEG(), destination: thailand)

        _ = Destination(
            context: context,
            placeName: "Amsterdam",
            subtitle: "Pays-Bas",
            coordinate: CLLocationCoordinate2D(latitude: 52.372, longitude: 4.899),
            visitDate: calendar.date(byAdding: .day, value: 12, to: .now) ?? .now,
            purpose: .discovery,
            family: family
        )

        _ = Destination(
            context: context,
            placeName: "Marseille",
            subtitle: "Provence-Alpes-Côte d'Azur, France",
            coordinate: CLLocationCoordinate2D(latitude: 43.296, longitude: 5.370),
            visitDate: calendar.date(byAdding: .day, value: 29, to: .now) ?? .now,
            purpose: .weekend,
            family: family
        )

        context.saveLoggingFailure()
    }

    /// Une « photo » de plage générée : dégradé ciel → mer → sable.
    private static func beachJPEG() -> Data {
        let size = CGSize(width: 1200, height: 800)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [
                UIColor(red: 0.49, green: 0.72, blue: 0.91, alpha: 1).cgColor,
                UIColor(red: 0.33, green: 0.69, blue: 0.84, alpha: 1).cgColor,
                UIColor(red: 0.98, green: 0.93, blue: 0.80, alpha: 1).cgColor
            ]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 0.55, 1]
            ) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: 0, y: size.height),
                    options: []
                )
            }
        }
        return image.jpegData(compressionQuality: 0.85) ?? Data()
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
