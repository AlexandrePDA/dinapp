import SwiftUI
import CoreData
import Charts

struct YearlyStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyManager.self) private var familyManager
    @FetchRequest(sortDescriptors: [SortDescriptor(\Destination.visitDate, order: .forward)]) private var allDestinations: FetchedResults<Destination>
    @FetchRequest(sortDescriptors: []) private var babies: FetchedResults<BabyProfile>
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var isExporting: Bool = false
    @State private var pdfDocument: JournalPDFTransferable?
    @State private var showExportError: Bool = false

    private var scopedDestinations: [Destination] {
        familyManager.scoped(allDestinations)
    }

    private var scopedBabyName: String {
        familyManager.scoped(babies).first?.name.nilIfBlank ?? "Bébé"
    }

    private var availableYears: [Int] {
        let years = YearlyStatsViewModel.availableYears(from: scopedDestinations)
        return years.isEmpty ? [Calendar.current.component(.year, from: .now)] : years
    }

    private var stats: YearlyStats {
        YearlyStatsViewModel.stats(for: selectedYear, destinations: scopedDestinations)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    yearSelector

                    if stats.hasData {
                        heroCount
                        statsGrid
                        purposeChart
                        topSection
                        comparisonRow
                        exportButton
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .padding(.bottom, 40)
            }
            .background(AppColors.background)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(AppColors.plumSoft)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rétrospective")
                .font(AppTypography.overline)
                .tracking(2)
                .foregroundStyle(AppColors.plumSoft)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("L'année")
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.plum)
                Text(String(selectedYear))
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.peachDeep)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        withAnimation(.smooth) { selectedYear = year }
                    } label: {
                        Text(String(year))
                            .font(AppTypography.subheadline)
                            .foregroundStyle(selectedYear == year ? .white : AppColors.plum)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selectedYear == year ? AppColors.peachDeep : AppColors.sand)
                            )
                            .overlay(
                                Capsule().strokeBorder(AppColors.peach.opacity(selectedYear == year ? 0 : 0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var heroCount: some View {
        ZStack {
            AsymmetricSquircle(topLeading: 42, topTrailing: 28, bottomLeading: 56, bottomTrailing: 38)
                .fill(
                    LinearGradient(
                        colors: [AppColors.peach.opacity(0.55), AppColors.butter.opacity(0.45), AppColors.sky.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            BlobShape(seed: 0.9)
                .fill(AppColors.butter.opacity(0.55))
                .frame(width: 180, height: 180)
                .offset(x: 100, y: -80)
                .blur(radius: 6)

            BlobShape(seed: 0.7)
                .fill(AppColors.sky.opacity(0.45))
                .frame(width: 160, height: 160)
                .offset(x: -110, y: 90)
                .blur(radius: 8)

            AsymmetricSquircle(topLeading: 42, topTrailing: 28, bottomLeading: 56, bottomTrailing: 38)
                .fill(.clear)
                .glassEffect(
                    .regular.tint(AppColors.peach.opacity(0.05)),
                    in: AsymmetricSquircle(topLeading: 42, topTrailing: 28, bottomLeading: 56, bottomTrailing: 38)
                )

            VStack(spacing: 8) {
                Text("\(stats.destinationsCount)")
                    .font(.system(size: 88, design: .serif).weight(.bold))
                    .foregroundStyle(AppColors.plum)
                Text(stats.destinationsCount <= 1 ? "escapade" : "escapades")
                    .font(AppTypography.editorial)
                    .foregroundStyle(AppColors.plum)
                if let first = stats.firstDestination, let last = stats.lastDestination {
                    Text("Du \(first.visitDate.formatted(.shortDay)) au \(last.visitDate.formatted(.shortDay))")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.plumSoft)
                        .padding(.top, 4)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(
            AsymmetricSquircle(topLeading: 42, topTrailing: 28, bottomLeading: 56, bottomTrailing: 38)
        )
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            PillStat(
                value: "\(stats.uniquePlacesCount)",
                label: "LIEUX UNIQUES",
                systemImage: "sparkles",
                tint: AppColors.butter
            )
            PillStat(
                value: distanceString,
                label: "KILOMÈTRES",
                systemImage: "figure.walk",
                tint: AppColors.sky
            )
        }
    }

    private var purposeChart: some View {
        SectionCard(title: "Par occasion", systemImage: "chart.pie", tint: AppColors.peach) {
            HStack(spacing: 20) {
                Chart(stats.purposeDistribution) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(AppColors.tint(for: slice.purpose))
                    .cornerRadius(4)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(stats.purposeDistribution) { slice in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppColors.tint(for: slice.purpose))
                                .frame(width: 10, height: 10)
                            Text(slice.purpose.label)
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppColors.plum)
                            Spacer(minLength: 0)
                            Text("\(slice.count)")
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppColors.plumSoft)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var topSection: some View {
        if !stats.topDestinations.isEmpty {
            SectionCard(title: "Points forts", systemImage: "star", tint: AppColors.butter) {
                VStack(spacing: 12) {
                    ForEach(Array(stats.topDestinations.enumerated()), id: \.element.identifier) { index, destination in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(AppTypography.editorial)
                                .foregroundStyle(AppColors.peachDeep)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(destination.placeName)
                                    .font(AppTypography.subheadline)
                                    .foregroundStyle(AppColors.plum)
                                Text(destination.visitDate.formatted(.shortDay).uppercased())
                                    .font(AppTypography.overline)
                                    .tracking(1.2)
                                    .foregroundStyle(AppColors.tint(for: destination.purpose))
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var comparisonRow: some View {
        if let comparison = stats.comparisonToPrevious {
            HStack(spacing: 10) {
                Image(systemName: comparison.delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundStyle(comparison.delta >= 0 ? AppColors.skyDeep : AppColors.peachDeep)
                Text(comparisonText(comparison))
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.plumSoft)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Capsule().fill(AppColors.sand))
            .overlay(Capsule().strokeBorder(AppColors.hairline, lineWidth: 1))
        }
    }

    private var exportButton: some View {
        Button {
            Task { await exportPDF() }
        } label: {
            HStack(spacing: 10) {
                if isExporting {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.callout.weight(.semibold))
                }
                Text(isExporting ? "Génération…" : "Exporter le journal en PDF")
                    .font(AppTypography.bodyEmphasized)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [AppColors.peach, AppColors.peachDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .shadow(color: AppColors.peachDeep.opacity(0.3), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isExporting)
        .padding(.top, 4)
        .sheet(item: $pdfDocument) { document in
            ShareSheet(activityItems: [document.url])
        }
        .alert("Export impossible", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Le PDF n'a pas pu être généré. Réessayez dans un instant.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.butter.opacity(0.35)).frame(width: 96, height: 96)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppColors.butterDeep)
            }
            Text("Aucune donnée pour \(selectedYear)")
                .font(AppTypography.editorial)
                .foregroundStyle(AppColors.plum)
            Text("Sélectionnez une autre année ou ajoutez une escapade.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.plumSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private var distanceString: String {
        stats.totalDistanceKm.kilometersLabel
    }

    private func comparisonText(_ comparison: YearlyStats.Comparison) -> String {
        let sign = comparison.delta >= 0 ? "+" : ""
        return "\(sign)\(comparison.delta) escapades vs \(comparison.previousYear) (\(comparison.previousCount) l'an dernier)"
    }

    private func exportPDF() async {
        isExporting = true
        defer { isExporting = false }
        let filtered = scopedDestinations.filter {
            Calendar.current.component(.year, from: $0.visitDate) == selectedYear
        }
        if let url = await JournalPDFExporter.exportJournal(
            year: selectedYear,
            babyName: scopedBabyName,
            destinations: filtered,
            stats: stats
        ) {
            pdfDocument = JournalPDFTransferable(url: url)
        } else {
            showExportError = true
        }
    }
}

struct JournalPDFTransferable: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
