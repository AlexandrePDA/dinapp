import SwiftUI
import CoreData

@main
struct DinaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("dina.hasOnboarded") private var hasOnboarded: Bool = false
    @State private var familyManager = FamilyManager()
    @State private var isShowingSplash = true
    private let persistence = PersistenceController.shared

    private static let splashDuration: Duration = .seconds(1.6)

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if hasOnboarded {
                        RootTabView()
                    } else {
                        OnboardingContainer()
                    }
                }

                if isShowingSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .tint(AppColors.accent)
            .preferredColorScheme(.light)
            .environment(familyManager)
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .task {
                try? await Task.sleep(for: Self.splashDuration)
                withAnimation(.easeOut(duration: 0.4)) {
                    isShowingSplash = false
                }
            }
        }
    }
}
