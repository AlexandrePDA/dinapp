import Foundation

extension Date {
    func formatted(_ style: DinaDateStyle) -> String {
        switch style {
        case .shortDay:
            return formatted(.dateTime.day().month(.abbreviated).locale(DinaDateStyle.locale))
        case .fullDay:
            return formatted(.dateTime.weekday(.wide).day().month(.wide).locale(DinaDateStyle.locale))
        case .monthYear:
            return formatted(.dateTime.month(.wide).year().locale(DinaDateStyle.locale))
        case .relative:
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = DinaDateStyle.locale
            formatter.unitsStyle = .full
            return formatter.localizedString(for: self, relativeTo: .now)
        }
    }
}

enum DinaDateStyle {
    case shortDay
    case fullDay
    case monthYear
    case relative

    /// L'app est éditée en français uniquement : les dates suivent.
    static let locale = Locale(identifier: "fr_FR")
}
