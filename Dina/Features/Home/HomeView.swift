import SwiftUI
import CoreData

struct HomeView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\Destination.visitDate, order: .forward)]) private var destinations: FetchedResults<Destination>
    @FetchRequest(sortDescriptors: []) private var babies: FetchedResults<BabyProfile>
    @Environment(FamilyManager.self) private var familyManager
    @State private var showYearlyStats: Bool = false
    @State private var showBadges: Bool = false
    @State private var selectedMemory: Destination?

    let onAdd: () -> Void

    private var scopedDestinations: [Destination] {
        familyManager.scoped(destinations)
    }

    private var scopedBabies: [BabyProfile] {
        familyManager.scoped(babies)
    }

    private var summary: HomeSummary {
        HomeViewModel.summary(from: scopedDestinations)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HeroBlob(
                    title: babyName,
                    subtitle: "Ses petites aventures, jour après jour.",
                    greeting: greeting,
                    ctaLabel: "Nouvelle escapade",
                    onCTA: onAdd
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)

                memorySection

                statsSection

                nextTripSection

                discoverRow

                recentTimelineSection
            }
            .padding(.bottom, 24)
        }
        .background(AppColors.background)
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showYearlyStats) {
            YearlyStatsView()
        }
        .sheet(isPresented: $showBadges) {
            BadgesView()
        }
        .sheet(item: $selectedMemory) { destination in
            DestinationDetailView(destination: destination)
        }
        .task(id: scopedDestinations.count) {
            await MemoryNotificationService.refresh(
                destinations: scopedDestinations,
                babyName: scopedBabies.first?.name
            )
        }
    }

    @ViewBuilder
    private var memorySection: some View {
        if let memory = summary.memoryDestination {
            Button {
                selectedMemory = memory
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Spacer(minLength: 0)
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("IL Y A UN AN")
                            .font(AppTypography.overline)
                            .tracking(1.8)
                    }
                    .foregroundStyle(AppColors.butter)
                    Text(memory.placeName)
                        .font(AppTypography.editorial)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(memory.visitDate.formatted(.fullDay).capitalized)
                        .font(AppTypography.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 170)
                .background { memoryBackground(for: memory) }
                .clipShape(AsymmetricSquircle(topLeading: 34, topTrailing: 22, bottomLeading: 22, bottomTrailing: 34))
                .overlay(
                    AsymmetricSquircle(topLeading: 34, topTrailing: 22, bottomLeading: 22, bottomTrailing: 34)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: AppColors.plum.opacity(0.22), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }

    private func memoryBackground(for memory: Destination) -> some View {
        ZStack {
            if let image = memory.sortedPhotos.first.flatMap({ UIImage.thumbnail(from: $0.imageData, maxDimension: 500) }) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppColors.sky, AppColors.skyDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "sparkles")
                    .font(.system(size: 90, weight: .light))
                    .foregroundStyle(.white.opacity(0.18))
                    .offset(x: 110, y: -30)
            }
            LinearGradient(
                colors: [.clear, AppColors.plum.opacity(0.70)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }

    private var badgesSubtitle: String {
        let statuses = BadgeEngine.statuses(from: scopedDestinations)
        let unlocked = statuses.filter(\.isUnlocked).count
        return unlocked == 0
            ? "À débloquer"
            : "\(unlocked) sur \(statuses.count) débloqué\(unlocked > 1 ? "s" : "")"
    }

    private var discoverRow: some View {
        HStack(spacing: 12) {
            discoverTile(
                title: "Badges",
                subtitle: badgesSubtitle,
                systemImage: "medal.fill",
                tint: AppColors.peach
            ) { showBadges = true }
            discoverTile(
                title: "Rétrospective",
                subtitle: "L'année en bref",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: AppColors.butter
            ) { showYearlyStats = true }
        }
        .padding(.horizontal, 20)
    }

    private func discoverTile(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(tint.opacity(0.35))
                        Image(systemName: systemImage)
                            .font(.callout)
                            .foregroundStyle(AppColors.plum)
                    }
                    .frame(width: 40, height: 40)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.plumSoft)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.plum)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.plumSoft)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AsymmetricSquircle(topLeading: 26, topTrailing: 18, bottomLeading: 18, bottomTrailing: 26)
                    .fill(tint.opacity(0.16))
            )
            .overlay(
                AsymmetricSquircle(topLeading: 26, topTrailing: 18, bottomLeading: 18, bottomTrailing: 26)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            CircleStat(
                value: "\(summary.destinationsCount)",
                label: "SORTIES",
                systemImage: "mappin.and.ellipse",
                tint: AppColors.peach
            )
            VStack(spacing: 12) {
                PillStat(
                    value: distanceString,
                    label: "KILOMÈTRES",
                    systemImage: "figure.walk",
                    tint: AppColors.sky
                )
                PillStat(
                    value: "\(summary.uniquePlaces)",
                    label: "LIEUX UNIQUES",
                    systemImage: "sparkles",
                    tint: AppColors.butter
                )
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var nextTripSection: some View {
        if let next = summary.nextDestination {
            SectionCard(
                title: "Prochaine escapade",
                systemImage: "airplane.departure",
                tint: AppColors.sky
            ) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle().fill(AppColors.tint(for: next.purpose).opacity(0.35))
                        Image(systemName: next.purpose.systemImage)
                            .foregroundStyle(AppColors.plum)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(next.placeName)
                            .font(AppTypography.title3)
                            .foregroundStyle(AppColors.plum)
                        Text(next.visitDate.formatted(.fullDay).capitalized)
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.plumSoft)
                        Text(next.purpose.label.uppercased())
                            .font(AppTypography.overline)
                            .tracking(1.4)
                            .foregroundStyle(AppColors.tint(for: next.purpose))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(AppColors.softTint(for: next.purpose))
                            )
                            .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var recentTimelineSection: some View {
        if !summary.recentDestinations.isEmpty {
            SectionCard(
                title: "Dernières aventures",
                systemImage: "clock.arrow.circlepath",
                tint: AppColors.butter
            ) {
                VStack(spacing: 0) {
                    ForEach(Array(summary.recentDestinations.enumerated()), id: \.element.identifier) { index, destination in
                        TimelineRow(
                            title: destination.placeName,
                            subtitle: destination.visitDate.formatted(.shortDay).uppercased(),
                            systemImage: destination.purpose.systemImage,
                            tint: AppColors.tint(for: destination.purpose),
                            isLast: index == summary.recentDestinations.count - 1
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var babyName: String {
        scopedBabies.first?.name.nilIfBlank ?? "Petit·e explorateur"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Bonjour"
        case 12..<18: return "Bel après-midi"
        default: return "Douce soirée"
        }
    }

    private var distanceString: String {
        summary.totalDistanceKm.kilometersLabel
    }
}
