import SwiftUI
import CoreData
import MapKit
import PhotosUI

struct DestinationDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let destination: Destination

    @State private var confirmDelete = false
    @State private var photoSelection: [PhotosPickerItem] = []
    @State private var isEditing = false
    @State private var viewerContext: PhotoViewerContext?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    photosSection
                    memorySection
                    tripSection
                    dateSection
                    locationSection

                    deleteButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(AppColors.plumSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Modifier") { isEditing = true }
                        .foregroundStyle(AppColors.peachDeep)
                        .font(AppTypography.bodyEmphasized)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isEditing) {
            AddDestinationSheet(destination: destination)
        }
        .fullScreenCover(item: $viewerContext) { context in
            PhotoViewer(context: context)
        }
        .alert("Supprimer cette escapade ?", isPresented: $confirmDelete) {
            Button("Supprimer", role: .destructive, action: delete)
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Elle disparaîtra du journal et de la carte.")
        }
    }

    private var tint: Color { AppColors.tint(for: destination.purpose) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(tint.opacity(0.35))
                    Image(systemName: destination.purpose.systemImage)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(AppColors.plum)
                }
                .frame(width: 40, height: 40)

                Text(destination.purpose.label.uppercased())
                    .font(AppTypography.overline)
                    .tracking(1.6)
                    .foregroundStyle(tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppColors.softTint(for: destination.purpose)))
                Spacer(minLength: 0)
            }

            Text(destination.placeName)
                .font(AppTypography.editorialLarge)
                .foregroundStyle(AppColors.plum)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            if !destination.subtitle.isEmpty {
                Text(destination.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.plumSoft)
            }
        }
    }

    private var photosSection: some View {
        SectionCard(title: "Les photos", systemImage: "photo.on.rectangle.angled", tint: AppColors.sky) {
            ScrollView(.horizontal, showsIndicators: false) {
                PhotoStrip(
                    images: destination.sortedPhotos.compactMap { UIImage.thumbnail(from: $0.imageData, maxDimension: 132) },
                    maxCount: PhotoImporter.maxPhotosPerDestination,
                    selection: $photoSelection,
                    onDelete: deletePhoto,
                    tileSize: 132,
                    onTap: openViewer
                )
                .padding(.top, 8)
            }
        }
        .onChange(of: photoSelection) {
            guard !photoSelection.isEmpty else { return }
            let items = photoSelection
            photoSelection = []
            Task { await addPhotos(items) }
        }
    }

    private func addPhotos(_ items: [PhotosPickerItem]) async {
        for data in await PhotoImporter.importImages(from: items) {
            _ = DestinationPhoto(context: context, imageData: data, destination: destination)
        }
        context.saveLoggingFailure()
    }

    private func openViewer(at index: Int) {
        let images = destination.sortedPhotos.compactMap { UIImage(data: $0.imageData) }
        guard images.indices.contains(index) else { return }
        viewerContext = PhotoViewerContext(images: images, startIndex: index)
    }

    private func deletePhoto(at index: Int) {
        let photos = destination.sortedPhotos
        guard photos.indices.contains(index) else { return }
        context.delete(photos[index])
        context.saveLoggingFailure()
    }

    @ViewBuilder
    private var memorySection: some View {
        if !destination.notes.isEmpty {
            SectionCard(title: "Le souvenir", systemImage: "text.quote", tint: AppColors.peach) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundStyle(AppColors.peachDeep)
                    Text(destination.notes)
                        .font(AppTypography.editorialSmall)
                        .foregroundStyle(AppColors.plum)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            SectionCard(title: "Le souvenir", systemImage: "text.quote", tint: AppColors.peach) {
                Text("Aucune anecdote ajoutée pour cette escapade.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.plumSoft)
            }
        }
    }

    @ViewBuilder
    private var tripSection: some View {
        if let trip = destination.trip {
            SectionCard(title: "Le séjour", systemImage: "suitcase.fill", tint: AppColors.skyDeep) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(trip.title)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.plum)

                    let otherStops = trip.sortedDestinations.filter { $0.identifier != destination.identifier }
                    if otherStops.isEmpty {
                        Text("Première étape de ce séjour.")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.plumSoft)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(otherStops, id: \.identifier) { stop in
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle().fill(AppColors.softTint(for: stop.purpose))
                                        Image(systemName: stop.purpose.systemImage)
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(AppColors.tint(for: stop.purpose))
                                    }
                                    .frame(width: 28, height: 28)
                                    Text(stop.placeName)
                                        .font(AppTypography.subheadline)
                                        .foregroundStyle(AppColors.plum)
                                    Spacer(minLength: 0)
                                    Text(stop.visitDate.formatted(.shortDay).uppercased())
                                        .font(AppTypography.overline)
                                        .tracking(1.2)
                                        .foregroundStyle(AppColors.plumSoft)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var dateSection: some View {
        SectionCard(title: "Quand", systemImage: "calendar", tint: AppColors.butter) {
            VStack(alignment: .leading, spacing: 8) {
                dateRow(label: "Arrivée", value: destination.visitDate.formatted(.fullDay).capitalized)
                if let departure = destination.departureDate {
                    Divider().overlay(AppColors.hairline)
                    dateRow(label: "Départ", value: departure.formatted(.fullDay).capitalized)
                    Divider().overlay(AppColors.hairline)
                    dateRow(label: "Durée", value: durationString(from: destination.visitDate, to: departure))
                }
            }
        }
    }

    private var locationSection: some View {
        SectionCard(title: "Sur la carte", systemImage: "map", tint: AppColors.sky) {
            VStack(alignment: .leading, spacing: 12) {
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: destination.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                ) {
                    Annotation(destination.placeName, coordinate: destination.coordinate, anchor: .bottom) {
                        ZStack {
                            Circle().fill(tint).frame(width: 30, height: 30)
                            Circle().strokeBorder(.white, lineWidth: 2).frame(width: 30, height: 30)
                            Image(systemName: destination.purpose.systemImage)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 180)
                .clipShape(AsymmetricSquircle(topLeading: 20, topTrailing: 12, bottomLeading: 12, bottomTrailing: 20))
                .allowsHitTesting(false)

                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.skyDeep)
                    Text("\(destination.coordinate.latitude, specifier: "%.4f"), \(destination.coordinate.longitude, specifier: "%.4f")")
                        .font(AppTypography.caption)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.plumSoft)
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            confirmDelete = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Supprimer cette escapade")
                    .font(AppTypography.bodyEmphasized)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(Color.red.opacity(0.85))
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private func dateRow(label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(AppTypography.overline)
                .tracking(1.4)
                .foregroundStyle(AppColors.plumSoft)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.plum)
        }
    }

    private func durationString(from start: Date, to end: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        if days == 0 { return "Journée" }
        if days == 1 { return "1 jour" }
        return "\(days) jours"
    }

    private func delete() {
        context.deleteDestination(destination)
        dismiss()
    }
}
