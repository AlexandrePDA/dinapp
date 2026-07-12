import SwiftUI

enum AppColors {
    static let peach = Color(red: 1.00, green: 0.608, blue: 0.478)
    static let peachDeep = Color(red: 0.949, green: 0.482, blue: 0.361)
    static let sky = Color(red: 0.494, green: 0.722, blue: 0.910)
    static let skyDeep = Color(red: 0.325, green: 0.573, blue: 0.788)
    static let butter = Color(red: 1.00, green: 0.851, blue: 0.478)
    static let butterDeep = Color(red: 0.976, green: 0.749, blue: 0.310)
    static let sand = Color(red: 1.00, green: 0.965, blue: 0.933)
    static let plum = Color(red: 0.239, green: 0.173, blue: 0.306)
    static let plumSoft = Color(red: 0.400, green: 0.322, blue: 0.475)

    static let accent = peach
    static let background = sand

    static let tertiaryText = Color(red: 0.55, green: 0.48, blue: 0.60)

    static let hairline = plum.opacity(0.10)

    static func tint(for purpose: TripPurpose) -> Color {
        switch purpose {
        case .family: return peach
        case .weekend: return butter
        case .vacation: return sky
        case .medical: return plumSoft
        case .discovery: return peachDeep
        case .other: return skyDeep
        }
    }

    static func softTint(for purpose: TripPurpose) -> Color {
        tint(for: purpose).opacity(0.22)
    }
}
