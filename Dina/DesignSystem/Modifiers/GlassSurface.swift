import SwiftUI

struct GlassCapsule: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(tint ?? .clear), in: .capsule)
    }
}

extension View {
    func glassChip(tint: Color? = nil) -> some View {
        modifier(GlassCapsule(tint: tint))
    }
}
