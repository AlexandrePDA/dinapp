import Foundation
import CoreLocation

struct HomeSummary {
    let destinationsCount: Int
    let uniquePlaces: Int
    let totalDistanceKm: Double
    let nextDestination: Destination?
    let recentDestinations: [Destination]
    let memoryDestination: Destination?
}

enum HomeViewModel {
    static func summary(from destinations: [Destination]) -> HomeSummary {
        let now = Date()
        let sorted = destinations.sorted { $0.visitDate < $1.visitDate }
        let uniqueNames = Set(destinations.map { $0.placeName.lowercased() })
        let next = sorted.first { $0.visitDate >= now }
        let recent = sorted
            .filter { $0.visitDate <= now }
            .suffix(5)
            .reversed()

        return HomeSummary(
            destinationsCount: destinations.count,
            uniquePlaces: uniqueNames.count,
            totalDistanceKm: sorted.totalTraveledKilometers,
            nextDestination: next,
            recentDestinations: Array(recent),
            memoryDestination: memoryDestination(from: sorted, now: now)
        )
    }

    /// La sortie la plus proche d'« il y a un an », à ±7 jours près.
    private static func memoryDestination(from ordered: [Destination], now: Date) -> Destination? {
        guard let target = Calendar.current.date(byAdding: .year, value: -1, to: now) else { return nil }
        let window: TimeInterval = 7 * 24 * 3600
        return ordered
            .filter { abs($0.visitDate.timeIntervalSince(target)) <= window }
            .min { abs($0.visitDate.timeIntervalSince(target)) < abs($1.visitDate.timeIntervalSince(target)) }
    }
}
