import UIKit
import PhotosUI
import SwiftUI

enum PhotoImporter {
    static let maxPhotosPerDestination = 3
    private static let maxDimension: CGFloat = 1600
    private static let compressionQuality: CGFloat = 0.75

    /// Charge les éléments choisis dans le sélecteur et les compresse
    /// pour un stockage (et une synchro iCloud) raisonnables.
    static func importImages(from items: [PhotosPickerItem]) async -> [Data] {
        var result: [Data] = []
        for item in items {
            guard
                let raw = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: raw),
                let data = image.resized(maxDimension: maxDimension)
                    .jpegData(compressionQuality: compressionQuality)
            else { continue }
            result.append(data)
        }
        return result
    }
}

extension UIImage {
    /// Décode une vignette directement à la taille cible via ImageIO,
    /// sans charger l'image entière en mémoire.
    static func thumbnail(from data: Data, maxDimension: CGFloat) -> UIImage? {
        // Échelle fixe (3x, densité max des iPhone) : évite UIScreen.main,
        // déprécié et isolé au main actor.
        let displayScale: CGFloat = 3
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension * displayScale
        ] as [CFString: Any] as CFDictionary
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options)
        else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func resized(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
