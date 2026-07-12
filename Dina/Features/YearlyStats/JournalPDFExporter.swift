import Foundation
import UIKit
import SwiftUI
import PDFKit

@MainActor
enum JournalPDFExporter {
    private static let pageSize = CGSize(width: 595, height: 842)
    private static let margin: CGFloat = 48

    /// Équivalents UIColor de la palette `AppColors`, pour le rendu PDF.
    private enum Palette {
        static let peach = UIColor(AppColors.peach)
        static let plum = UIColor(AppColors.plum)
        static let plumSoft = UIColor(AppColors.plumSoft)
        static let sand = UIColor(AppColors.sand).withAlphaComponent(0.9)
        static let hairline = UIColor(red: 0.85, green: 0.83, blue: 0.87, alpha: 1)

        static func tint(for purpose: TripPurpose) -> UIColor {
            UIColor(AppColors.tint(for: purpose))
        }
    }

    static func exportJournal(
        year: Int,
        babyName: String,
        destinations: [Destination],
        stats: YearlyStats
    ) async -> URL? {
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: makeFormat()
        )

        let data = renderer.pdfData { context in
            drawCoverPage(context: context, year: year, babyName: babyName, stats: stats)
            drawBadgesPage(context: context, destinations: destinations)
            drawJournalPages(context: context, year: year, destinations: destinations)
        }

        return saveToTemp(data: data, year: year, babyName: babyName)
    }

    private static func makeFormat() -> UIGraphicsPDFRendererFormat {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Dinapp",
            kCGPDFContextTitle as String: "Journal de bord"
        ]
        return format
    }

    private static func saveToTemp(data: Data, year: Int, babyName: String) -> URL? {
        let filename = "Journal-\(babyName)-\(year).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            AppLog.export.error("Échec d'écriture du PDF : \(String(describing: error))")
            return nil
        }
    }

    // MARK: - Cover

    private static func drawCoverPage(
        context: UIGraphicsPDFRendererContext,
        year: Int,
        babyName: String,
        stats: YearlyStats
    ) {
        context.beginPage()
        let cg = context.cgContext

        drawGradientBackground(cg: cg)

        let peach = Palette.peach
        let plum = Palette.plum
        let plumSoft = Palette.plumSoft

        if let logo = UIImage(named: "AppLogo") {
            let logoSize: CGFloat = 72
            let logoRect = CGRect(x: margin, y: 100, width: logoSize, height: logoSize)
            let logoPath = UIBezierPath(roundedRect: logoRect, cornerRadius: 16)
            cg.saveGState()
            logoPath.addClip()
            logo.draw(in: logoRect)
            cg.restoreGState()
        }

        var y: CGFloat = 200
        drawText("JOURNAL DE BORD", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 12, weight: .semibold), color: plumSoft, tracking: 4)

        y += 30
        drawText("L'année", at: CGPoint(x: margin, y: y), font: serif(size: 56, weight: .semibold, italic: true), color: plum)

        y += 68
        drawText(String(year), at: CGPoint(x: margin, y: y), font: serif(size: 56, weight: .bold, italic: false), color: peach)

        y += 90
        drawText("de \(babyName)", at: CGPoint(x: margin, y: y), font: serif(size: 26, weight: .medium, italic: true), color: plum)

        let boxY: CGFloat = 550
        let boxWidth = pageSize.width - margin * 2
        drawStatBox(cg: cg, at: CGRect(x: margin, y: boxY, width: boxWidth, height: 130), stats: stats)

        drawText(
            "Généré avec Dinapp",
            at: CGPoint(x: margin, y: pageSize.height - 60),
            font: .systemFont(ofSize: 10, weight: .medium),
            color: plumSoft,
            tracking: 2
        )
    }

    private static func drawStatBox(cg: CGContext, at rect: CGRect, stats: YearlyStats) {
        let plum = Palette.plum
        let plumSoft = Palette.plumSoft

        let path = UIBezierPath(roundedRect: rect, cornerRadius: 22)
        Palette.sand.setFill()
        path.fill()

        let items: [(String, String)] = [
            ("\(stats.destinationsCount)", "ESCAPADES"),
            ("\(stats.uniquePlacesCount)", "LIEUX"),
            (String(format: "%.0f km", stats.totalDistanceKm), "PARCOURUS")
        ]

        let itemWidth = rect.width / CGFloat(items.count)
        for (index, item) in items.enumerated() {
            let x = rect.minX + CGFloat(index) * itemWidth + itemWidth / 2
            let valueRect = CGRect(x: x - 60, y: rect.minY + 22, width: 120, height: 44)
            let labelRect = CGRect(x: x - 60, y: rect.minY + 72, width: 120, height: 20)

            drawCenteredText(item.0, in: valueRect, font: serif(size: 36, weight: .semibold, italic: false), color: plum)
            drawCenteredText(item.1, in: labelRect, font: .systemFont(ofSize: 10, weight: .semibold), color: plumSoft, tracking: 2)
        }
    }

    private static func drawGradientBackground(cg: CGContext) {
        let colors = [
            UIColor(red: 1.0, green: 0.965, blue: 0.933, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.90, blue: 0.85, alpha: 1).cgColor,
            UIColor(red: 0.94, green: 0.92, blue: 0.98, alpha: 1).cgColor
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.5, 1]) else { return }
        cg.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: pageSize.width, y: pageSize.height),
            options: []
        )

        // Blob decorative
        let butter = UIColor(red: 1.0, green: 0.851, blue: 0.478, alpha: 0.45).cgColor
        cg.setFillColor(butter)
        cg.fillEllipse(in: CGRect(x: pageSize.width - 160, y: -80, width: 260, height: 260))

        let sky = UIColor(red: 0.494, green: 0.722, blue: 0.910, alpha: 0.35).cgColor
        cg.setFillColor(sky)
        cg.fillEllipse(in: CGRect(x: -120, y: pageSize.height - 200, width: 320, height: 320))
    }

    // MARK: - Badges

    private static func drawBadgesPage(
        context: UIGraphicsPDFRendererContext,
        destinations: [Destination]
    ) {
        let unlocked = BadgeEngine.statuses(from: destinations)
            .filter(\.isUnlocked)
            .map(\.badge)
        guard !unlocked.isEmpty else { return }

        context.beginPage()
        let cg = context.cgContext
        drawGradientBackground(cg: cg)

        let plum = Palette.plum
        let plumSoft = Palette.plumSoft

        var y: CGFloat = 100
        drawText("COLLECTION", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 12, weight: .semibold), color: plumSoft, tracking: 4)
        y += 26
        drawText("Les badges", at: CGPoint(x: margin, y: y), font: serif(size: 40, weight: .semibold, italic: true), color: plum)
        y += 56
        drawText(
            "\(unlocked.count) souvenir\(unlocked.count > 1 ? "s" : "") débloqué\(unlocked.count > 1 ? "s" : "") sur \(BadgeEngine.all.count)",
            at: CGPoint(x: margin, y: y),
            font: .systemFont(ofSize: 12, weight: .medium),
            color: plumSoft
        )
        y += 44

        let columns = 3
        let cellWidth = (pageSize.width - margin * 2) / CGFloat(columns)
        let cellHeight: CGFloat = 110
        let circleSize: CGFloat = 54

        for (index, badge) in unlocked.enumerated() {
            let column = index % columns
            let row = index / columns
            let cellX = margin + CGFloat(column) * cellWidth
            let cellY = y + CGFloat(row) * cellHeight
            guard cellY + cellHeight < pageSize.height - margin else { break }

            let tint = UIColor(badge.tint)
            let circleRect = CGRect(
                x: cellX + (cellWidth - circleSize) / 2,
                y: cellY,
                width: circleSize,
                height: circleSize
            )
            tint.withAlphaComponent(0.30).setFill()
            UIBezierPath(ovalIn: circleRect).fill()
            let ring = UIBezierPath(ovalIn: circleRect.insetBy(dx: 1, dy: 1))
            ring.lineWidth = 2
            tint.setStroke()
            ring.stroke()

            let iconConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            if let icon = UIImage(systemName: badge.systemImage, withConfiguration: iconConfig)?
                .withTintColor(plum, renderingMode: .alwaysOriginal) {
                let iconSize = icon.size
                // Les symboles SF teintés sortent en rectangle plein dans un
                // contexte PDF : on les aplatit d'abord en bitmap.
                let format = UIGraphicsImageRendererFormat()
                format.scale = 3
                let bitmap = UIGraphicsImageRenderer(size: iconSize, format: format).image { _ in
                    icon.draw(in: CGRect(origin: .zero, size: iconSize))
                }
                bitmap.draw(in: CGRect(
                    x: circleRect.midX - iconSize.width / 2,
                    y: circleRect.midY - iconSize.height / 2,
                    width: iconSize.width,
                    height: iconSize.height
                ))
            }

            drawCenteredText(
                badge.title,
                in: CGRect(x: cellX + 4, y: circleRect.maxY + 6, width: cellWidth - 8, height: 16),
                font: .systemFont(ofSize: 11, weight: .semibold),
                color: plum
            )
            drawCenteredText(
                badge.detail,
                in: CGRect(x: cellX + 4, y: circleRect.maxY + 24, width: cellWidth - 8, height: 26),
                font: .systemFont(ofSize: 9, weight: .regular),
                color: plumSoft
            )
        }
    }

    // MARK: - Journal pages

    private static func drawJournalPages(
        context: UIGraphicsPDFRendererContext,
        year: Int,
        destinations: [Destination]
    ) {
        let sorted = destinations.sorted { $0.visitDate < $1.visitDate }
        guard !sorted.isEmpty else { return }

        let plum = Palette.plum
        let plumSoft = Palette.plumSoft
        let hairline = Palette.hairline

        var currentMonth: Int = -1
        var y: CGFloat = margin + 40

        func newPage() {
            context.beginPage()
            drawGradientBackground(cg: context.cgContext)
            drawText(
                "Journal · \(year)",
                at: CGPoint(x: margin, y: margin),
                font: serif(size: 16, weight: .medium, italic: true),
                color: plumSoft
            )
            y = margin + 40
        }

        newPage()

        let calendar = Calendar.current
        for destination in sorted {
            let month = calendar.component(.month, from: destination.visitDate)

            let hasPhoto = !destination.sortedPhotos.isEmpty
            if y > pageSize.height - (hasPhoto ? 340 : 180) {
                newPage()
            }

            if month != currentMonth {
                currentMonth = month
                y += 8
                drawText(
                    destination.visitDate.formatted(.monthYear).capitalized,
                    at: CGPoint(x: margin, y: y),
                    font: serif(size: 22, weight: .semibold, italic: true),
                    color: plum
                )
                y += 32
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: margin, y: y))
                linePath.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
                hairline.setStroke()
                linePath.lineWidth = 0.5
                linePath.stroke()
                y += 18
            }

            drawDestinationBlock(destination: destination, at: &y, context: context)
        }
    }

    private static func drawDestinationBlock(
        destination: Destination,
        at y: inout CGFloat,
        context: UIGraphicsPDFRendererContext
    ) {
        let plum = Palette.plum
        let plumSoft = Palette.plumSoft
        let tint = Palette.tint(for: destination.purpose)

        let dotSize: CGFloat = 12
        let dotY = y + 4
        let dotPath = UIBezierPath(ovalIn: CGRect(x: margin, y: dotY, width: dotSize, height: dotSize))
        tint.setFill()
        dotPath.fill()

        let contentX = margin + dotSize + 12
        let contentWidth = pageSize.width - contentX - margin

        drawText(
            destination.visitDate.formatted(.shortDay).uppercased() + "   ·   " + destination.purpose.label.uppercased(),
            at: CGPoint(x: contentX, y: y),
            font: .systemFont(ofSize: 10, weight: .semibold),
            color: tint,
            tracking: 2
        )
        y += 18

        drawText(
            destination.placeName,
            at: CGPoint(x: contentX, y: y),
            font: serif(size: 20, weight: .semibold, italic: false),
            color: plum
        )
        y += 28

        if !destination.notes.isEmpty {
            let notesHeight = drawWrappedText(
                destination.notes,
                in: CGRect(x: contentX, y: y, width: contentWidth, height: 200),
                font: serif(size: 13, weight: .regular, italic: true),
                color: plumSoft
            )
            y += notesHeight + 8
        }

        let photos = destination.sortedPhotos.map(\.imageData)
        if !photos.isEmpty {
            drawPhotoRow(photos, at: CGPoint(x: contentX, y: y), maxWidth: contentWidth, cg: context.cgContext)
            y += photoHeight + 8
        }

        y += 20
    }

    private static let photoHeight: CGFloat = 140

    private static func drawPhotoRow(_ photos: [Data], at origin: CGPoint, maxWidth: CGFloat, cg: CGContext) {
        let spacing: CGFloat = 8
        let count = CGFloat(photos.count)
        let width = min(200, (maxWidth - spacing * (count - 1)) / count)
        for (index, data) in photos.enumerated() {
            let rect = CGRect(
                x: origin.x + CGFloat(index) * (width + spacing),
                y: origin.y,
                width: width,
                height: photoHeight
            )
            drawPhoto(data, in: rect, cg: cg)
        }
    }

    private static func drawPhoto(_ data: Data, in rect: CGRect, cg: CGContext) {
        guard let image = UIImage(data: data) else { return }
        cg.saveGState()
        UIBezierPath(roundedRect: rect, cornerRadius: 14).addClip()
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        ))
        cg.restoreGState()
    }

    // MARK: - Drawing helpers

    private static func serif(size: CGFloat, weight: UIFont.Weight, italic: Bool) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        var traits: UIFontDescriptor.SymbolicTraits = []
        if italic { traits.insert(.traitItalic) }
        let final = descriptor.withSymbolicTraits(traits) ?? descriptor
        return UIFont(descriptor: final, size: size)
    }

    private static func drawText(
        _ string: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor,
        tracking: CGFloat = 0
    ) {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        if tracking > 0 { attributes[.kern] = tracking }
        NSString(string: string).draw(at: point, withAttributes: attributes)
    }

    private static func drawCenteredText(
        _ string: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        tracking: CGFloat = 0
    ) {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: {
                let ps = NSMutableParagraphStyle()
                ps.alignment = .center
                return ps
            }()
        ]
        if tracking > 0 { attributes[.kern] = tracking }
        NSString(string: string).draw(in: rect, withAttributes: attributes)
    }

    @discardableResult
    private static func drawWrappedText(
        _ string: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let bounds = attributed.boundingRect(
            with: CGSize(width: rect.width, height: rect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return bounds.height
    }
}
