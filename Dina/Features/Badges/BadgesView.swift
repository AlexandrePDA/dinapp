import SwiftUI
import CoreData

struct BadgesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyManager.self) private var familyManager
    @FetchRequest(sortDescriptors: []) private var destinations: FetchedResults<Destination>

    private var scopedDestinations: [Destination] {
        familyManager.scoped(destinations)
    }

    private var statuses: [BadgeStatus] {
        BadgeEngine.statuses(from: scopedDestinations)
    }

    private var unlockedCount: Int {
        statuses.filter(\.isUnlocked).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(statuses) { status in
                            BadgeCard(status: status)
                        }
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
            Text("Collection")
                .font(AppTypography.overline)
                .tracking(2)
                .foregroundStyle(AppColors.plumSoft)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("Les")
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.plum)
                Text("badges")
                    .font(AppTypography.editorialLarge)
                    .foregroundStyle(AppColors.peachDeep)
            }
            Text("\(unlockedCount) débloqué\(unlockedCount > 1 ? "s" : "") sur \(statuses.count)")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.plumSoft)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

private struct BadgeCard: View {
    let status: BadgeStatus

    private var badge: Badge { status.badge }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(status.isUnlocked ? badge.tint.opacity(0.30) : AppColors.plum.opacity(0.06))
                Circle()
                    .strokeBorder(
                        status.isUnlocked ? badge.tint : AppColors.plum.opacity(0.12),
                        lineWidth: 2
                    )
                Image(systemName: badge.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(status.isUnlocked ? AppColors.plum : AppColors.plum.opacity(0.25))
            }
            .frame(width: 56, height: 56)

            VStack(spacing: 3) {
                Text(badge.title)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(status.isUnlocked ? AppColors.plum : AppColors.plumSoft)
                    .multilineTextAlignment(.center)
                Text(badge.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.plumSoft.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            if status.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                    Text("DÉBLOQUÉ")
                        .font(AppTypography.overline)
                        .tracking(1.2)
                }
                .foregroundStyle(badge.tint == AppColors.butter ? AppColors.butterDeep : badge.tint)
            } else {
                VStack(spacing: 4) {
                    ProgressView(value: status.fraction)
                        .tint(badge.tint)
                        .frame(maxWidth: 72)
                    Text("\(status.progress) / \(badge.target)")
                        .font(AppTypography.overline)
                        .tracking(1)
                        .foregroundStyle(AppColors.plumSoft.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 190, alignment: .top)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            AsymmetricSquircle(topLeading: 26, topTrailing: 18, bottomLeading: 18, bottomTrailing: 26)
                .fill(status.isUnlocked ? badge.tint.opacity(0.14) : Color.white.opacity(0.45))
        )
        .overlay(
            AsymmetricSquircle(topLeading: 26, topTrailing: 18, bottomLeading: 18, bottomTrailing: 26)
                .strokeBorder(
                    status.isUnlocked ? badge.tint.opacity(0.35) : AppColors.hairline,
                    lineWidth: 1
                )
        )
    }
}
