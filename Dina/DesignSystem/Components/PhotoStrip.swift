import SwiftUI
import PhotosUI

/// Bande de photos avec bouton d'ajout : utilisée à la création d'une
/// escapade et dans son détail. La sélection est vidée par le parent
/// une fois les images importées.
struct PhotoStrip: View {
    let images: [UIImage]
    let maxCount: Int
    @Binding var selection: [PhotosPickerItem]
    let onDelete: (Int) -> Void
    var tileSize: CGFloat = 76
    var onTap: ((Int) -> Void)?

    private var remainingSlots: Int { max(0, maxCount - images.count) }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                thumbnail(image, index: index)
            }
            if remainingSlots > 0 {
                addButton
            }
            Spacer(minLength: 0)
        }
    }

    private func thumbnail(_ image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: tileSize, height: tileSize)
            .clipShape(AsymmetricSquircle(topLeading: 20, topTrailing: 12, bottomLeading: 12, bottomTrailing: 20))
            .contentShape(AsymmetricSquircle(topLeading: 20, topTrailing: 12, bottomLeading: 12, bottomTrailing: 20))
            .onTapGesture { onTap?(index) }
            .overlay(
                AsymmetricSquircle(topLeading: 20, topTrailing: 12, bottomLeading: 12, bottomTrailing: 20)
                    .strokeBorder(.white.opacity(0.6), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Button {
                    onDelete(index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppColors.plum.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Supprimer la photo")
                .offset(x: 6, y: -6)
            }
    }

    private var addButton: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: remainingSlots,
            matching: .images
        ) {
            ZStack {
                AsymmetricSquircle(topLeading: 20, topTrailing: 12, bottomLeading: 12, bottomTrailing: 20)
                    .fill(AppColors.sand)
                AsymmetricSquircle(topLeading: 20, topTrailing: 12, bottomLeading: 12, bottomTrailing: 20)
                    .strokeBorder(AppColors.plum.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3.weight(.semibold))
                    Text("Ajouter")
                        .font(AppTypography.caption)
                }
                .foregroundStyle(AppColors.plumSoft)
            }
            .frame(width: tileSize, height: tileSize)
        }
        .buttonStyle(.plain)
    }
}
