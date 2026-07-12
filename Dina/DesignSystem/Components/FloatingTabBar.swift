import SwiftUI

struct FloatingTabBar: View {
    @Binding var selected: DinaTab
    let onAdd: () -> Void

    private let tabs: [DinaTab] = [.home, .map, .journal, .settings]

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(for: tabs[0])
                tabButton(for: tabs[1])
                Color.clear.frame(width: 60, height: 1)
                tabButton(for: tabs[2])
                tabButton(for: tabs[3])
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(AppColors.sand.opacity(0.35)), in: .capsule)
            )
            .overlay(
                Capsule().strokeBorder(AppColors.plum.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: AppColors.plum.opacity(0.15), radius: 22, x: 0, y: 12)

            addFAB
                .offset(y: -18)
        }
        .padding(.horizontal, 24)
    }

    private func tabButton(for tab: DinaTab) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.28)) {
                selected = tab
            }
        } label: {
            Image(systemName: tab.systemImage)
                .font(.title3.weight(.semibold))
                .symbolVariant(selected == tab ? .fill : .none)
                .foregroundStyle(selected == tab ? AppColors.plum : AppColors.plumSoft.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .accessibilityLabel(tab.title)
            .background {
                if selected == tab {
                    Capsule()
                        .fill(AppColors.peach.opacity(0.20))
                        .matchedGeometryEffect(id: "tabbg", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addFAB: some View {
        Button(action: onAdd) {
            ZStack {
                Circle()
                    .fill(AppColors.sand)
                    .frame(width: 62, height: 62)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.peach, AppColors.peachDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppColors.peachDeep.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nouvelle escapade")
    }

    @Namespace private var namespace
}
