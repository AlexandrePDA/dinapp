import SwiftUI

struct BlobShape: Shape {
    var seed: CGFloat = 0.6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let cornerBase = min(width, height) * seed

        path.move(to: CGPoint(x: 0, y: cornerBase * 0.8))
        path.addCurve(
            to: CGPoint(x: cornerBase * 0.9, y: 0),
            control1: CGPoint(x: 0, y: cornerBase * 0.2),
            control2: CGPoint(x: cornerBase * 0.3, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: width - cornerBase * 0.4, y: cornerBase * 0.15),
            control1: CGPoint(x: cornerBase * 1.4, y: 0),
            control2: CGPoint(x: width - cornerBase * 1.1, y: -cornerBase * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: width, y: cornerBase * 1.0),
            control1: CGPoint(x: width - cornerBase * 0.05, y: cornerBase * 0.3),
            control2: CGPoint(x: width, y: cornerBase * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: width - cornerBase * 0.3, y: height),
            control1: CGPoint(x: width, y: height - cornerBase * 0.5),
            control2: CGPoint(x: width - cornerBase * 0.05, y: height)
        )
        path.addCurve(
            to: CGPoint(x: cornerBase * 0.4, y: height - cornerBase * 0.2),
            control1: CGPoint(x: cornerBase * 1.2, y: height + cornerBase * 0.05),
            control2: CGPoint(x: cornerBase * 0.05, y: height + cornerBase * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: cornerBase * 0.8),
            control1: CGPoint(x: -cornerBase * 0.05, y: height - cornerBase * 0.6),
            control2: CGPoint(x: 0, y: cornerBase * 1.4)
        )
        path.closeSubpath()
        return path
    }
}

struct AsymmetricSquircle: InsettableShape {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CGFloat
    let bottomTrailing: CGFloat
    var insetAmount: CGFloat = 0

    init(
        topLeading: CGFloat = 24,
        topTrailing: CGFloat = 40,
        bottomLeading: CGFloat = 40,
        bottomTrailing: CGFloat = 24
    ) {
        self.topLeading = topLeading
        self.topTrailing = topTrailing
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
    }

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return UnevenRoundedRectangle(
            topLeadingRadius: max(0, topLeading - insetAmount),
            bottomLeadingRadius: max(0, bottomLeading - insetAmount),
            bottomTrailingRadius: max(0, bottomTrailing - insetAmount),
            topTrailingRadius: max(0, topTrailing - insetAmount),
            style: .continuous
        )
        .path(in: insetRect)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
