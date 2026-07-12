import Foundation

enum TripPurpose: String, CaseIterable, Codable, Identifiable {
    case family
    case weekend
    case vacation
    case medical
    case discovery
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .family: "Famille"
        case .weekend: "Week-end"
        case .vacation: "Vacances"
        case .medical: "Rendez-vous"
        case .discovery: "Découverte"
        case .other: "Autre"
        }
    }

    var systemImage: String {
        switch self {
        case .family: "person.2.fill"
        case .weekend: "sun.max.fill"
        case .vacation: "beach.umbrella.fill"
        case .medical: "cross.case.fill"
        case .discovery: "sparkles"
        case .other: "mappin.and.ellipse"
        }
    }
}
