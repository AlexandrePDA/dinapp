import SwiftUI
import MapKit

struct LocationSearchList: View {
    let suggestions: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion) -> Void

    var body: some View {
        if suggestions.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(AppColors.sky.opacity(0.25))
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(AppColors.skyDeep)
                            }
                            .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .font(AppTypography.subheadline)
                                    .foregroundStyle(AppColors.plum)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColors.plumSoft)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if suggestion != suggestions.last {
                        Divider().overlay(AppColors.hairline)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.plumSoft)
            Text("Ville, adresse, monument…")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.plumSoft)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}
