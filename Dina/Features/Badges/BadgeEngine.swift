import SwiftUI
import CoreLocation

struct Badge: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    let target: Int
}

struct BadgeStatus: Identifiable {
    let badge: Badge
    let progress: Int

    var id: String { badge.id }
    var isUnlocked: Bool { progress >= badge.target }
    var fraction: Double { min(Double(progress) / Double(badge.target), 1) }
}

enum BadgeEngine {
    static func statuses(from destinations: [Destination]) -> [BadgeStatus] {
        let past = destinations
            .filter { $0.visitDate <= .now }
            .sorted { $0.visitDate < $1.visitDate }

        let placeCounts = Dictionary(grouping: past) { $0.placeName.lowercased() }
            .mapValues(\.count)
        let monthCounts = Dictionary(grouping: past) { destination in
            Calendar.current.dateComponents([.year, .month], from: destination.visitDate)
        }
        .mapValues(\.count)
        let seasons = Set(past.map { season(for: $0.visitDate) })
        let purposes = Set(past.map(\.purpose))
        let notesCount = past.filter { !$0.notes.isEmpty }.count
        let distanceKm = past.totalTraveledKilometers

        func value(for id: String) -> Int {
            switch id {
            case "premiers-pas", "petit-curieux", "explorateur", "grand-aventurier":
                past.count
            case "premier-weekend":
                past.contains { $0.purpose == .weekend } ? 1 : 0
            case "premieres-vacances":
                past.contains { $0.purpose == .vacation } ? 1 : 0
            case "collectionneur", "cartographe":
                placeCounts.count
            case "quatre-saisons":
                seasons.count
            case "cent-kilometres", "grand-voyageur":
                Int(distanceKm)
            case "mois-anime":
                monthCounts.values.max() ?? 0
            case "notre-petit-coin":
                placeCounts.values.max() ?? 0
            case "touche-a-tout":
                purposes.count
            case "conteur":
                notesCount
            default:
                0
            }
        }

        return all.map { BadgeStatus(badge: $0, progress: value(for: $0.id)) }
    }

    static let all: [Badge] = [
        Badge(
            id: "premiers-pas",
            title: "Premiers pas",
            detail: "Enregistrer la toute première sortie",
            systemImage: "shoeprints.fill",
            tint: AppColors.peach,
            target: 1
        ),
        Badge(
            id: "premier-weekend",
            title: "Premier week-end",
            detail: "Vivre une première sortie week-end",
            systemImage: "sun.max.fill",
            tint: AppColors.butter,
            target: 1
        ),
        Badge(
            id: "premieres-vacances",
            title: "Premières vacances",
            detail: "Partir en vacances pour la première fois",
            systemImage: "beach.umbrella.fill",
            tint: AppColors.sky,
            target: 1
        ),
        Badge(
            id: "petit-curieux",
            title: "Petit curieux",
            detail: "Cumuler 5 sorties",
            systemImage: "binoculars.fill",
            tint: AppColors.peachDeep,
            target: 5
        ),
        Badge(
            id: "explorateur",
            title: "Explorateur",
            detail: "Cumuler 20 sorties",
            systemImage: "map.fill",
            tint: AppColors.skyDeep,
            target: 20
        ),
        Badge(
            id: "grand-aventurier",
            title: "Grand aventurier",
            detail: "Cumuler 50 sorties",
            systemImage: "medal.fill",
            tint: AppColors.butterDeep,
            target: 50
        ),
        Badge(
            id: "collectionneur",
            title: "Collectionneur de lieux",
            detail: "Découvrir 10 lieux différents",
            systemImage: "mappin.and.ellipse",
            tint: AppColors.peach,
            target: 10
        ),
        Badge(
            id: "cartographe",
            title: "Cartographe en herbe",
            detail: "Découvrir 25 lieux différents",
            systemImage: "globe.europe.africa.fill",
            tint: AppColors.sky,
            target: 25
        ),
        Badge(
            id: "quatre-saisons",
            title: "Les 4 saisons",
            detail: "Sortir au printemps, en été, en automne et en hiver",
            systemImage: "leaf.fill",
            tint: AppColors.butter,
            target: 4
        ),
        Badge(
            id: "cent-kilometres",
            title: "100 kilomètres",
            detail: "Parcourir 100 km d'aventures",
            systemImage: "figure.walk",
            tint: AppColors.skyDeep,
            target: 100
        ),
        Badge(
            id: "grand-voyageur",
            title: "Grand voyageur",
            detail: "Parcourir 1 000 km d'aventures",
            systemImage: "airplane",
            tint: AppColors.peachDeep,
            target: 1000
        ),
        Badge(
            id: "mois-anime",
            title: "Mois bien rempli",
            detail: "Faire 5 sorties dans le même mois",
            systemImage: "calendar",
            tint: AppColors.butterDeep,
            target: 5
        ),
        Badge(
            id: "notre-petit-coin",
            title: "Notre petit coin",
            detail: "Retourner 3 fois au même endroit",
            systemImage: "heart.fill",
            tint: AppColors.peach,
            target: 3
        ),
        Badge(
            id: "touche-a-tout",
            title: "Touche-à-tout",
            detail: "Vivre une sortie de chaque occasion",
            systemImage: "square.grid.2x2.fill",
            tint: AppColors.plumSoft,
            target: TripPurpose.allCases.count
        ),
        Badge(
            id: "conteur",
            title: "Conteur d'histoires",
            detail: "Noter 10 souvenirs dans le journal",
            systemImage: "quote.opening",
            tint: AppColors.skyDeep,
            target: 10
        )
    ]

    private static func season(for date: Date) -> Int {
        switch Calendar.current.component(.month, from: date) {
        case 3...5: 0
        case 6...8: 1
        case 9...11: 2
        default: 3
        }
    }
}
