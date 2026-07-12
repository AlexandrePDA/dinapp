import SwiftUI
import CoreData

struct RootTabView: View {
    @Environment(\.managedObjectContext) private var modelContext
    @Environment(FamilyManager.self) private var familyManager
    @State private var selectedTab: DinaTab = .home
    @State private var isPresentingAdd = false

    var body: some View {
        currentTabView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                FloatingTabBar(selected: $selectedTab, onAdd: { isPresentingAdd = true })
                    .padding(.top, 24)
                    .padding(.bottom, 8)
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddDestinationSheet()
            }
            .overlay {
                BadgeCelebrationOverlay()
            }
            .task {
                familyManager.bootstrap(with: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: .sharingAccepted)) { _ in
                familyManager.adoptSharedFamily(context: modelContext)
            }
            .onReceive(
                NotificationCenter.default
                    .publisher(for: .NSPersistentStoreRemoteChange)
                    .receive(on: DispatchQueue.main)
            ) { _ in
                // La famille partagée peut arriver après l'acceptation,
                // au fil de l'import CloudKit.
                familyManager.adoptSharedFamilyIfNeeded(context: modelContext)
            }
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .home:
            HomeView(onAdd: { isPresentingAdd = true })
        case .map:
            MapScreen()
        case .journal:
            JournalView()
        case .settings:
            SettingsView()
        }
    }
}

enum DinaTab: Hashable {
    case home
    case map
    case journal
    case settings

    var title: String {
        switch self {
        case .home: "Accueil"
        case .map: "Carte"
        case .journal: "Journal"
        case .settings: "Réglages"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .map: "map"
        case .journal: "book.pages"
        case .settings: "gearshape"
        }
    }
}
