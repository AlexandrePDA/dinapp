import SwiftUI

struct PhotoViewerContext: Identifiable {
    let id = UUID()
    let images: [UIImage]
    let startIndex: Int
}

/// Visionneuse plein écran : navigation par balayage entre les photos.
struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int

    private let images: [UIImage]

    init(context: PhotoViewerContext) {
        images = context.images
        _index = State(initialValue: context.startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(images.enumerated()), id: \.offset) { position, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .white.opacity(0.25))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fermer")
            .padding(20)
        }
        .statusBarHidden()
    }
}
