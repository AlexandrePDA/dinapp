import SwiftUI
import CoreData
import MapKit

struct MapScreen: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\Destination.visitDate, order: .forward)]) private var destinations: FetchedResults<Destination>
    @Environment(FamilyManager.self) private var familyManager
    @State private var position: MapCameraPosition = .automatic
    @State private var selection: UUID?
    @State private var openedDestination: Destination?
    @State private var showBadges: Bool = false

    private var scopedDestinations: [Destination] {
        familyManager.scoped(destinations)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selection) {
                ForEach(scopedDestinations, id: \.identifier) { destination in
                    Annotation(
                        destination.placeName,
                        coordinate: destination.coordinate,
                        anchor: .bottom
                    ) {
                        DestinationPin(purpose: destination.purpose, isSelected: selection == destination.identifier)
                    }
                    .tag(destination.identifier)
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.park, .beach])))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea(edges: .bottom)

            floatingHeader

            if let selected = scopedDestinations.first(where: { $0.identifier == selection }) {
                DestinationPreviewCard(destination: selected) {
                    openedDestination = selected
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: selection)
        .onAppear { fitAllDestinations() }
        .sheet(item: $openedDestination) { destination in
            DestinationDetailView(destination: destination)
        }
        .sheet(isPresented: $showBadges) {
            BadgesView()
        }
    }

    private var uniquePlacesCount: Int {
        Set(scopedDestinations.map { $0.placeName.lowercased() }).count
    }

    private var floatingHeader: some View {
        HStack(spacing: 10) {
            Text("Carte")
                .font(AppTypography.editorial)
                .foregroundStyle(AppColors.plum)
            Button {
                showBadges = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "medal.fill")
                        .font(.caption2)
                    Text("\(uniquePlacesCount) lieu\(uniquePlacesCount > 1 ? "x" : "")")
                        .font(AppTypography.overline)
                        .tracking(1.2)
                }
                .foregroundStyle(AppColors.plumSoft)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(AppColors.sand.opacity(0.5)), in: .capsule)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func fitAllDestinations() {
        let items = scopedDestinations
        guard !items.isEmpty else { return }
        let coordinates = items.map(\.coordinate)
        let region = MKCoordinateRegion.enclosing(coordinates)
        position = .region(region)
    }
}

private struct DestinationPin: View {
    let purpose: TripPurpose
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.tint(for: purpose), AppColors.tint(for: purpose).opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                .overlay(
                    Circle().strokeBorder(.white, lineWidth: 2)
                )
                .shadow(color: AppColors.plum.opacity(0.35), radius: 6, x: 0, y: 4)

            Image(systemName: purpose.systemImage)
                .font(isSelected ? .callout.weight(.bold) : .footnote.weight(.bold))
                .foregroundStyle(.white)
        }
        .animation(.smooth, value: isSelected)
    }
}

private struct DestinationPreviewCard: View {
    let destination: Destination
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(AppColors.softTint(for: destination.purpose))
                        Image(systemName: destination.purpose.systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppColors.tint(for: destination.purpose))
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(destination.placeName)
                            .font(AppTypography.title3)
                            .foregroundStyle(AppColors.plum)
                            .multilineTextAlignment(.leading)
                        Text(destination.visitDate.formatted(.fullDay).capitalized)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.plumSoft)
                        Text(destination.purpose.label.uppercased())
                            .font(AppTypography.overline)
                            .tracking(1.2)
                            .foregroundStyle(AppColors.tint(for: destination.purpose))
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.tint(for: destination.purpose))
                }

                if !destination.notes.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.tint(for: destination.purpose))
                        Text(destination.notes)
                            .font(AppTypography.footnote)
                            .italic()
                            .foregroundStyle(AppColors.plum.opacity(0.85))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                    )
                }
            }
            .padding(18)
            .background(
                AsymmetricSquircle(topLeading: 30, topTrailing: 20, bottomLeading: 20, bottomTrailing: 30)
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(AppColors.softTint(for: destination.purpose)),
                        in: AsymmetricSquircle(topLeading: 30, topTrailing: 20, bottomLeading: 20, bottomTrailing: 30)
                    )
            )
            .overlay(
                AsymmetricSquircle(topLeading: 30, topTrailing: 20, bottomLeading: 20, bottomTrailing: 30)
                    .strokeBorder(AppColors.tint(for: destination.purpose).opacity(0.35), lineWidth: 1)
            )
            .shadow(color: AppColors.plum.opacity(0.2), radius: 22, x: 0, y: 12)
        }
        .buttonStyle(.plain)
    }
}

extension MKCoordinateRegion {
    static func enclosing(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: .init(latitude: 46.5, longitude: 2.5),
                span: .init(latitudeDelta: 10, longitudeDelta: 10)
            )
        }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.05),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.05)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
