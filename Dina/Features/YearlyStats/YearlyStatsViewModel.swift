import Foundation
import CoreLocation

struct YearlyStats {
    let year: Int
    let destinationsCount: Int
    let uniquePlacesCount: Int
    let totalDistanceKm: Double
    let purposeDistribution: [PurposeSlice]
    let topDestinations: [Destination]
    let firstDestination: Destination?
    let lastDestination: Destination?
    let comparisonToPrevious: Comparison?
    let hasData: Bool

    struct PurposeSlice: Identifiable {
        let purpose: TripPurpose
        let count: Int
        var id: String { purpose.rawValue }
    }

    struct Comparison {
        let previousYear: Int
        let previousCount: Int
        let delta: Int
    }
}

enum YearlyStatsViewModel {
    static func availableYears(from destinations: [Destination]) -> [Int] {
        let years = destinations.map { Calendar.current.component(.year, from: $0.visitDate) }
        let unique = Set(years)
        return unique.sorted(by: >)
    }

    static func stats(for year: Int, destinations: [Destination]) -> YearlyStats {
        let calendar = Calendar.current
        let yearly = destinations.filter { calendar.component(.year, from: $0.visitDate) == year }
        let previous = destinations.filter { calendar.component(.year, from: $0.visitDate) == year - 1 }

        let uniquePlaces = Set(yearly.map { $0.placeName.lowercased() }).count
        let sorted = yearly.sorted { $0.visitDate < $1.visitDate }

        let distribution = TripPurpose.allCases
            .map { purpose in
                YearlyStats.PurposeSlice(
                    purpose: purpose,
                    count: yearly.filter { $0.purpose == purpose }.count
                )
            }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }

        let topDestinations = Array(yearly.sorted { $0.visitDate > $1.visitDate }.prefix(3))

        let comparison: YearlyStats.Comparison? = previous.isEmpty ? nil : YearlyStats.Comparison(
            previousYear: year - 1,
            previousCount: previous.count,
            delta: yearly.count - previous.count
        )

        return YearlyStats(
            year: year,
            destinationsCount: yearly.count,
            uniquePlacesCount: uniquePlaces,
            totalDistanceKm: sorted.totalTraveledKilometers,
            purposeDistribution: distribution,
            topDestinations: topDestinations,
            firstDestination: sorted.first,
            lastDestination: sorted.last,
            comparisonToPrevious: comparison,
            hasData: !yearly.isEmpty
        )
    }
}
