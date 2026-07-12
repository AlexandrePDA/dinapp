import Foundation
import UserNotifications

/// Planifie des notifications locales aux anniversaires des sorties
/// (« Il y a un an, vous étiez à… »), à 9 h le jour J.
@MainActor
enum MemoryNotificationService {
    private static let identifierPrefix = "memory-"
    private static let horizonDays = 60
    private static let maxScheduled = 20

    struct Anniversary {
        let destinationID: UUID
        let placeName: String
        let yearsAgo: Int
        let fireDate: Date
    }

    static func refresh(destinations: [Destination], babyName: String?) async {
        let planned = upcomingAnniversaries(for: destinations)
        // Rien à planifier : on ne dérange pas l'utilisateur avec
        // une demande d'autorisation prématurée.
        guard !planned.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        var settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            settings = await center.notificationSettings()
        }
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else { return }

        let pending = await center.pendingNotificationRequests()
        let ourIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ourIdentifiers)

        let name = babyName?.nilIfBlank ?? "bébé"
        for anniversary in planned {
            let content = UNMutableNotificationContent()
            content.title = anniversary.yearsAgo == 1
                ? "Il y a un an…"
                : "Il y a \(anniversary.yearsAgo) ans…"
            content.body = "Vous étiez à \(anniversary.placeName) avec \(name). Ouvrez le journal pour revivre ce souvenir."
            content.sound = .default

            var components = Calendar.current.dateComponents([.year, .month, .day], from: anniversary.fireDate)
            components.hour = 9
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(anniversary.destinationID.uuidString)-\(anniversary.yearsAgo)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }

    /// Les anniversaires (1 à 10 ans) qui tombent dans les 60 prochains jours.
    static func upcomingAnniversaries(for destinations: [Destination]) -> [Anniversary] {
        let calendar = Calendar.current
        let now = Date()
        guard let horizon = calendar.date(byAdding: .day, value: horizonDays, to: now) else { return [] }

        var result: [Anniversary] = []
        for destination in destinations {
            for years in 1...10 {
                guard
                    let anniversary = calendar.date(byAdding: .year, value: years, to: destination.visitDate),
                    anniversary > now, anniversary <= horizon
                else { continue }
                result.append(Anniversary(
                    destinationID: destination.identifier,
                    placeName: destination.placeName,
                    yearsAgo: years,
                    fireDate: anniversary
                ))
            }
        }
        return Array(result.sorted { $0.fireDate < $1.fireDate }.prefix(maxScheduled))
    }
}
