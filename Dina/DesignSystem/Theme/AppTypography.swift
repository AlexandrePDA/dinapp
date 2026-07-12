import SwiftUI

enum AppTypography {
    static let editorialLarge = Font.system(size: 40, design: .serif).weight(.semibold).italic()
    static let editorial = Font.system(.title, design: .serif, weight: .semibold).italic()
    static let editorialSmall = Font.system(.title3, design: .serif, weight: .medium).italic()

    static let title2 = Font.system(.title2, design: .serif, weight: .semibold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)

    static let body = Font.system(.body, design: .default, weight: .regular)
    static let bodyEmphasized = Font.system(.body, design: .default, weight: .medium)
    static let callout = Font.system(.callout, design: .default, weight: .regular)
    static let subheadline = Font.system(.subheadline, design: .default, weight: .medium)
    static let footnote = Font.system(.footnote, design: .default, weight: .regular)
    static let caption = Font.system(.caption, design: .rounded, weight: .semibold)
    static let overline = Font.system(.caption2, design: .rounded, weight: .semibold)
}
