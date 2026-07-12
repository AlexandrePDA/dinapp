import SwiftUI
import CoreData

@main
struct DinaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("dina.hasOnboarded") private var hasOnboarded: Bool = false
    @State private var familyManager = FamilyManager()
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootTabView()
                } else {
                    OnboardingContainer()
                }
            }
            .tint(AppColors.accent)
            .preferredColorScheme(.light)
            .environment(familyManager)
            .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
