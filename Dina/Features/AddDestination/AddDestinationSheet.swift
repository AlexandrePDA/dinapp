import SwiftUI
import CoreData
import MapKit
import PhotosUI

struct AddDestinationSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyManager.self) private var familyManager

    @State private var viewModel: AddDestinationViewModel
    @StateObject private var search = LocationSearchService()
    @State private var errorMessage: String?
    @State private var photoSelection: [PhotosPickerItem] = []
    @FetchRequest(sortDescriptors: [SortDescriptor(\Trip.createdAt, order: .reverse)]) private var trips: FetchedResults<Trip>

    private let editedDestination: Destination?

    init(destination: Destination? = nil) {
        editedDestination = destination
        let viewModel = AddDestinationViewModel()
        if let destination {
            viewModel.load(from: destination)
        }
        _viewModel = State(initialValue: viewModel)
    }

    private var scopedTrips: [Trip] {
        familyManager.scoped(trips)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    locationSection
                    datesSection
                    purposeSection
                    tripSection
                    notesSection
                    if editedDestination == nil {
                        photosSection
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .scrollIndicators(.hidden)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(AppColors.plumSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                        .disabled(!viewModel.canSave)
                        .foregroundStyle(viewModel.canSave ? AppColors.peachDeep : AppColors.tertiaryText)
                        .font(AppTypography.bodyEmphasized)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(editedDestination == nil ? "Nouvelle" : "Modifier")
                .font(AppTypography.editorialLarge)
                .foregroundStyle(AppColors.plum)
            Text(editedDestination == nil ? "escapade" : "l'escapade")
                .font(AppTypography.editorialLarge)
                .foregroundStyle(AppColors.peachDeep)
                .offset(x: 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var locationSection: some View {
        SectionCard(title: "Où va-t-on ?", systemImage: "mappin", tint: AppColors.sky) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Rechercher un endroit…", text: $search.query)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(AppColors.sand)
                    )
                    .overlay(
                        Capsule().strokeBorder(AppColors.sky.opacity(0.3), lineWidth: 1)
                    )
                LocationSearchList(suggestions: search.suggestions) { completion in
                    Task { await resolve(completion) }
                }
                if let coord = viewModel.coordinate {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.sky)
                        Text("\(viewModel.placeName) — \(coord.latitude, specifier: "%.3f"), \(coord.longitude, specifier: "%.3f")")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.plumSoft)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var datesSection: some View {
        SectionCard(title: "Quand ?", systemImage: "calendar", tint: AppColors.butter) {
            VStack(alignment: .leading, spacing: 10) {
                DatePicker("Arrivée", selection: $viewModel.visitDate, displayedComponents: [.date])
                    .tint(AppColors.peachDeep)
                Toggle("Ajouter une date de départ", isOn: $viewModel.hasDeparture)
                    .tint(AppColors.peach)
                if viewModel.hasDeparture {
                    DatePicker(
                        "Départ",
                        selection: $viewModel.departureDate,
                        in: viewModel.visitDate...,
                        displayedComponents: [.date]
                    )
                    .tint(AppColors.peachDeep)
                }
            }
            .foregroundStyle(AppColors.plum)
        }
    }

    private var purposeSection: some View {
        SectionCard(title: "Pour quelle occasion ?", systemImage: "sparkles", tint: AppColors.peach) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TripPurpose.allCases) { purpose in
                        Button {
                            viewModel.purpose = purpose
                        } label: {
                            PurposeChip(purpose: purpose, isSelected: viewModel.purpose == purpose)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var notesSection: some View {
        SectionCard(title: "Souvenirs", systemImage: "text.quote", tint: AppColors.plumSoft) {
            TextField("Une anecdote, un moment fort…", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .foregroundStyle(AppColors.plum)
        }
    }

    private var tripSection: some View {
        SectionCard(title: "Un séjour ?", systemImage: "suitcase.fill", tint: AppColors.skyDeep) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Regroupez les étapes d'une même vacance ou d'un même voyage.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.plumSoft)

                Menu {
                    Button("Aucun séjour") {
                        viewModel.selectedTrip = nil
                        viewModel.isCreatingTrip = false
                    }
                    ForEach(scopedTrips, id: \.identifier) { trip in
                        Button(trip.title) {
                            viewModel.selectedTrip = trip
                            viewModel.isCreatingTrip = false
                        }
                    }
                    Divider()
                    Button("Nouveau séjour…", systemImage: "plus") {
                        viewModel.selectedTrip = nil
                        viewModel.isCreatingTrip = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "suitcase.fill")
                            .font(.footnote)
                        Text(tripChoiceLabel)
                            .font(AppTypography.body)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(AppColors.plum)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppColors.sand))
                    .overlay(Capsule().strokeBorder(AppColors.skyDeep.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if viewModel.isCreatingTrip {
                    TextField("Ex : Été en Bretagne", text: $viewModel.newTripTitle)
                        .textInputAutocapitalization(.sentences)
                        .foregroundStyle(AppColors.plum)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(AppColors.sand))
                        .overlay(Capsule().strokeBorder(AppColors.skyDeep.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    private var tripChoiceLabel: String {
        if viewModel.isCreatingTrip { return "Nouveau séjour" }
        return viewModel.selectedTrip?.title ?? "Aucun séjour"
    }

    private var photosSection: some View {
        SectionCard(title: "Photos", systemImage: "photo.on.rectangle.angled", tint: AppColors.sky) {
            PhotoStrip(
                images: viewModel.photoData.compactMap(UIImage.init(data:)),
                maxCount: PhotoImporter.maxPhotosPerDestination,
                selection: $photoSelection,
                onDelete: { viewModel.photoData.remove(at: $0) }
            )
        }
        .onChange(of: photoSelection) {
            guard !photoSelection.isEmpty else { return }
            let items = photoSelection
            photoSelection = []
            Task {
                viewModel.photoData.append(contentsOf: await PhotoImporter.importImages(from: items))
            }
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        do {
            let item = try await search.resolve(completion)
            viewModel.apply(mapItem: item)
            search.reset()
        } catch {
            errorMessage = "Impossible de trouver ce lieu."
        }
    }

    private func save() {
        do {
            let family = familyManager.currentFamily(in: context)
            if let editedDestination {
                try viewModel.update(editedDestination, in: context, family: family)
            } else {
                try viewModel.save(into: context, family: family)
            }
            dismiss()
        } catch {
            errorMessage = "Enregistrement impossible : \(error.localizedDescription)"
        }
    }
}
