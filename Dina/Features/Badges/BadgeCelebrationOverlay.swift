import SwiftUI
import CoreData

struct BadgeCelebrationOverlay: View {
    @Environment(FamilyManager.self) private var familyManager
    @FetchRequest(sortDescriptors: []) private var destinations: FetchedResults<Destination>
    @State private var queue: [Badge] = []

    private var scopedDestinations: [Destination] {
        familyManager.scoped(destinations)
    }

    private var unlockedIDs: Set<String> {
        Set(
            BadgeEngine.statuses(from: scopedDestinations)
                .filter(\.isUnlocked)
                .map(\.id)
        )
    }

    private var storageKey: String {
        "celebratedBadges.\(familyManager.currentFamilyID?.uuidString ?? "default")"
    }

    var body: some View {
        ZStack {
            if let badge = queue.first {
                celebration(for: badge)
                    .id(badge.id)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.25), value: queue.first?.id)
        .onAppear { reconcile(celebrate: false) }
        .onChange(of: unlockedIDs) { reconcile(celebrate: true) }
        .onChange(of: storageKey) { reconcile(celebrate: false) }
    }

    /// Compare les badges débloqués aux badges déjà célébrés ; au premier
    /// passage (ou après un gros lot venu de la synchro iCloud) on mémorise
    /// sans célébrer pour éviter une rafale de cartes.
    private func reconcile(celebrate: Bool) {
        let defaults = UserDefaults.standard
        let unlocked = unlockedIDs
        guard let seen = defaults.stringArray(forKey: storageKey) else {
            defaults.set(Array(unlocked), forKey: storageKey)
            return
        }
        let fresh = unlocked.subtracting(seen)
        guard !fresh.isEmpty else { return }
        defaults.set(Array(unlocked.union(seen)), forKey: storageKey)
        guard celebrate, fresh.count <= 3 else { return }
        let badges = BadgeEngine.all.filter { fresh.contains($0.id) }
        withAnimation { queue.append(contentsOf: badges) }
    }

    private func advance() {
        withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
            if !queue.isEmpty { queue.removeFirst() }
        }
    }

    private func celebration(for badge: Badge) -> some View {
        ZStack {
            AppColors.plum.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            ConfettiBurst()

            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(badge.tint.opacity(0.30))
                    Circle().strokeBorder(badge.tint, lineWidth: 3)
                    Image(systemName: badge.systemImage)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(AppColors.plum)
                }
                .frame(width: 110, height: 110)
                .padding(.top, 6)

                VStack(spacing: 6) {
                    Text("NOUVEAU BADGE")
                        .font(AppTypography.overline)
                        .tracking(2)
                        .foregroundStyle(badge.tint == AppColors.butter ? AppColors.butterDeep : badge.tint)
                    Text(badge.title)
                        .font(AppTypography.editorial)
                        .foregroundStyle(AppColors.plum)
                        .multilineTextAlignment(.center)
                    Text(badge.detail)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.plumSoft)
                        .multilineTextAlignment(.center)
                }

                Button(action: advance) {
                    Text(queue.count > 1 ? "Suivant" : "Youpi !")
                        .font(AppTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [AppColors.peach, AppColors.peachDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .shadow(color: AppColors.peachDeep.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(
                AsymmetricSquircle(topLeading: 38, topTrailing: 26, bottomLeading: 26, bottomTrailing: 38)
                    .fill(AppColors.sand)
            )
            .overlay(
                AsymmetricSquircle(topLeading: 38, topTrailing: 26, bottomLeading: 26, bottomTrailing: 38)
                    .strokeBorder(badge.tint.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: AppColors.plum.opacity(0.3), radius: 30, x: 0, y: 16)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}

private struct ConfettiBurst: View {
    @State private var startDate = Date()

    private static let colors: [Color] = [
        AppColors.peach, AppColors.butter, AppColors.sky,
        AppColors.peachDeep, AppColors.skyDeep, AppColors.butterDeep
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed < 4 else { return }
                var random = SeededRandom(seed: 7)
                for _ in 0..<70 {
                    let column = random.next()
                    let delay = random.next() * 0.8
                    let speed = 170 + random.next() * 170
                    let sway = 10 + random.next() * 40
                    let phase = random.next() * .pi * 2
                    let colorIndex = Int(random.next() * Double(Self.colors.count)) % Self.colors.count

                    let t = elapsed - delay
                    guard t > 0 else { continue }
                    let y = t * speed - 30
                    guard y < size.height + 20 else { continue }
                    let x = column * size.width + sin(t * 3 + phase) * sway

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(t * 4 + phase))
                    ctx.opacity = min(1, max(0, 3.6 - t))
                    ctx.fill(
                        Path(CGRect(x: -4, y: -2.5, width: 8, height: 5)),
                        with: .color(Self.colors[colorIndex])
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// Générateur pseudo-aléatoire déterministe : chaque frame du Canvas rejoue
/// la même séquence, donc chaque confetti garde sa trajectoire.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 2_685_821_657_736_338_717 &+ 1
    }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 10_000) / 10_000
    }
}
