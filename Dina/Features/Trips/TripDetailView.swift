import SwiftUI
import CoreData

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var trip: Trip

    @State private var selectedDestination: Destination?
    @State private var isRenaming = false
    @State private var newTitle = ""

    var body: some View {
        // Un séjour vidé de sa dernière étape est supprimé automatiquement
        // (y compris depuis l'autre appareil) : on ferme au lieu de relire
        // un objet invalidé.
        if trip.isDeleted || trip.managedObjectContext == nil {
            Color.clear.onAppear { dismiss() }
        } else {
            content
        }
    }

    private var content: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    stopsSection
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
                    Button("Renommer") {
                        newTitle = trip.title
                        isRenaming = true
                    }
                    .foregroundStyle(AppColors.peachDeep)
                    .font(AppTypography.bodyEmphasized)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(item: $selectedDestination) { destination in
            DestinationDetailView(destination: destination)
        }
        .alert("Renommer le séjour", isPresented: $isRenaming) {
            TextField("Titre du séjour", text: $newTitle)
            Button("Enregistrer", action: rename)
            Button("Annuler", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "suitcase.fill")
                    .font(.caption)
                Text("SÉJOUR")
                    .font(AppTypography.overline)
                    .tracking(2)
            }
            .foregroundStyle(AppColors.skyDeep)

            Text(trip.title)
                .font(AppTypography.editorialLarge)
                .foregroundStyle(AppColors.plum)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            if let range = trip.dateRangeLabel {
                Text("\(trip.stepsCountLabel) · \(range)")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.plumSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stopsSection: some View {
        SectionCard(title: "Les étapes", systemImage: "mappin.and.ellipse", tint: AppColors.skyDeep) {
            VStack(spacing: 4) {
                ForEach(trip.sortedDestinations, id: \.identifier) { stop in
                    Button {
                        selectedDestination = stop
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(AppColors.softTint(for: stop.purpose))
                                Image(systemName: stop.purpose.systemImage)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppColors.tint(for: stop.purpose))
                            }
                            .frame(width: 34, height: 34)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(stop.placeName)
                                    .font(AppTypography.subheadline)
                                    .foregroundStyle(AppColors.plum)
                                    .multilineTextAlignment(.leading)
                                Text(stop.visitDate.formatted(.shortDay).uppercased())
                                    .font(AppTypography.overline)
                                    .tracking(1.2)
                                    .foregroundStyle(AppColors.plumSoft)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppColors.plumSoft)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func rename() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        trip.title = title
        context.saveLoggingFailure()
    }
}
