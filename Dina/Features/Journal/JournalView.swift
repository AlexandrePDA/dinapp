import SwiftUI
import CoreData

struct JournalView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(FamilyManager.self) private var familyManager
    @FetchRequest(sortDescriptors: [SortDescriptor(\Destination.visitDate, order: .reverse)]) private var destinations: FetchedResults<Destination>
    @FetchRequest(sortDescriptors: [SortDescriptor(\Trip.createdAt, order: .reverse)]) private var trips: FetchedResults<Trip>
    @FetchRequest(sortDescriptors: []) private var babies: FetchedResults<BabyProfile>
    @State private var selectedDestination: Destination?
    @State private var selectedTrip: Trip?
    @State private var isExporting: Bool = false
    @State private var pdfDocument: JournalPDFTransferable?
    @State private var showExportError: Bool = false

    private var scopedDestinations: [Destination] {
        familyManager.scoped(destinations)
    }

    private var scopedTrips: [Trip] {
        familyManager.scoped(trips)
    }

    private var scopedBabyName: String {
        familyManager.scoped(babies).first?.name.nilIfBlank ?? "Bébé"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                tripsSection

                if scopedDestinations.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedByMonth, id: \.key) { section in
                        VStack(alignment: .leading, spacing: 14) {
                            monthHeader(section.key, count: section.value.count)

                            VStack(spacing: 0) {
                                ForEach(Array(section.value.enumerated()), id: \.element.identifier) { index, destination in
                                    JournalEntryCard(
                                        destination: destination,
                                        isFirst: index == 0,
                                        isLast: index == section.value.count - 1,
                                        onDelete: { delete(destination) },
                                        onTap: { selectedDestination = destination }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppColors.background)
        .scrollIndicators(.hidden)
        .sheet(item: $selectedDestination) { destination in
            DestinationDetailView(destination: destination)
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailView(trip: trip)
        }
        .sheet(item: $pdfDocument) { document in
            ShareSheet(activityItems: [document.url])
        }
        .alert("Export impossible", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Le PDF n'a pas pu être généré. Réessayez dans un instant.")
        }
    }

    @ViewBuilder
    private var tripsSection: some View {
        if !scopedTrips.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                monthHeader("Séjours", count: scopedTrips.count)
                    .padding(.horizontal, 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(scopedTrips, id: \.identifier) { trip in
                            tripCard(trip)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func tripCard(_ trip: Trip) -> some View {
        Button {
            selectedTrip = trip
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(AppColors.sky.opacity(0.35))
                        Image(systemName: "suitcase.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.skyDeep)
                    }
                    .frame(width: 30, height: 30)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppColors.plumSoft)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.title)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.plum)
                        .lineLimit(1)
                    Text(tripSubtitle(trip))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.plumSoft)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(width: 190, alignment: .leading)
            .background(
                AsymmetricSquircle(topLeading: 24, topTrailing: 16, bottomLeading: 16, bottomTrailing: 24)
                    .fill(AppColors.sky.opacity(0.14))
            )
            .overlay(
                AsymmetricSquircle(topLeading: 24, topTrailing: 16, bottomLeading: 16, bottomTrailing: 24)
                    .strokeBorder(AppColors.sky.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func tripSubtitle(_ trip: Trip) -> String {
        guard let range = trip.dateRangeLabel else { return trip.stepsCountLabel }
        return "\(trip.stepsCountLabel) · \(range)"
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Journal")
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.plum)
                Text("de bord")
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.peachDeep)
                    .offset(x: 24)
            }
            Spacer(minLength: 0)
            if !scopedDestinations.isEmpty {
                exportButton
            }
        }
        .padding(.horizontal, 20)
    }

    private var exportButton: some View {
        Button {
            Task { await exportPDF() }
        } label: {
            HStack(spacing: 6) {
                if isExporting {
                    ProgressView().controlSize(.small).tint(AppColors.plum)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.footnote.weight(.semibold))
                }
                Text("PDF")
                    .font(AppTypography.caption)
                    .tracking(1)
            }
            .foregroundStyle(AppColors.plum)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassChip(tint: AppColors.peach.opacity(0.35))
        }
        .buttonStyle(.plain)
        .disabled(isExporting)
        .padding(.top, 12)
    }

    private func exportPDF() async {
        isExporting = true
        defer { isExporting = false }
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: .now)
        let stats = YearlyStatsViewModel.stats(for: currentYear, destinations: scopedDestinations)
        if let url = await JournalPDFExporter.exportJournal(
            year: currentYear,
            babyName: scopedBabyName,
            destinations: scopedDestinations,
            stats: stats
        ) {
            pdfDocument = JournalPDFTransferable(url: url)
        } else {
            showExportError = true
        }
    }

    private func monthHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(AppTypography.editorial)
                .foregroundStyle(AppColors.plum)
            Text("\(count)")
                .font(AppTypography.overline)
                .tracking(1.4)
                .foregroundStyle(AppColors.plumSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(AppColors.butter.opacity(0.35)))
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.peach.opacity(0.25))
                    .frame(width: 96, height: 96)
                Image(systemName: "book.closed")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppColors.peachDeep)
            }
            .padding(.top, 32)
            Text("Le journal est vide")
                .font(AppTypography.editorial)
                .foregroundStyle(AppColors.plum)
            Text("Ajoutez une escapade et elle apparaîtra ici,\nclassée jour par jour.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.plumSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private var groupedByMonth: [(key: String, value: [Destination])] {
        let groups = Dictionary(grouping: scopedDestinations) { destination in
            destination.visitDate.formatted(.monthYear).capitalized
        }
        return groups.sorted { lhs, rhs in
            guard let lhsFirst = lhs.value.first, let rhsFirst = rhs.value.first else { return false }
            return lhsFirst.visitDate > rhsFirst.visitDate
        }
    }

    private func delete(_ destination: Destination) {
        context.deleteDestination(destination)
    }
}

private struct JournalEntryCard: View {
    let destination: Destination
    let isFirst: Bool
    let isLast: Bool
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : AppColors.plum.opacity(0.15))
                    .frame(width: 2, height: 12)
                ZStack {
                    Circle().fill(AppColors.tint(for: destination.purpose))
                    Circle().strokeBorder(.white, lineWidth: 2)
                    Image(systemName: destination.purpose.systemImage)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 28, height: 28)
                Rectangle()
                    .fill(isLast ? Color.clear : AppColors.plum.opacity(0.15))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 28)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(destination.visitDate.formatted(.shortDay).uppercased())
                            .font(AppTypography.overline)
                            .tracking(1.4)
                            .foregroundStyle(AppColors.tint(for: destination.purpose))
                        Spacer(minLength: 0)
                        Text(destination.purpose.label)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.plumSoft)
                    }
                    Text(destination.placeName)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.plum)
                        .multilineTextAlignment(.leading)

                    if let trip = destination.trip {
                        HStack(spacing: 5) {
                            Image(systemName: "suitcase.fill")
                                .font(.caption2)
                            Text(trip.title)
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(AppColors.plumSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.55)))
                        .padding(.top, 2)
                    }

                    if !destination.notes.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.tint(for: destination.purpose))
                            Text(destination.notes)
                                .font(AppTypography.callout)
                                .italic()
                                .foregroundStyle(AppColors.plum.opacity(0.85))
                                .lineLimit(4)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, 6)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.55))
                        )
                        .padding(.top, 4)
                    }

                    if !destination.sortedPhotos.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(destination.sortedPhotos) { photo in
                                if let image = UIImage.thumbnail(from: photo.imageData, maxDimension: 64) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(
                                            AsymmetricSquircle(topLeading: 16, topTrailing: 10, bottomLeading: 10, bottomTrailing: 16)
                                        )
                                        .overlay(
                                            AsymmetricSquircle(topLeading: 16, topTrailing: 10, bottomLeading: 10, bottomTrailing: 16)
                                                .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    AsymmetricSquircle(topLeading: 28, topTrailing: 16, bottomLeading: 16, bottomTrailing: 28)
                        .fill(AppColors.softTint(for: destination.purpose))
                )
                .overlay(
                    AsymmetricSquircle(topLeading: 28, topTrailing: 16, bottomLeading: 16, bottomTrailing: 28)
                        .strokeBorder(AppColors.tint(for: destination.purpose).opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Supprimer", systemImage: "trash")
                }
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }
}
