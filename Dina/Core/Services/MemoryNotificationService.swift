import Foundation
import UserNotifications

/// Planifie les notifications locales de l'app, à 9 h le jour J :
/// - anniversaires des sorties (« Il y a un an, vous étiez à… ») ;
/// - anniversaire du bébé, avec une invitation à revenir dans l'app.
@MainActor
enum MemoryNotificationService {
    private static let memoryPrefix = "memory-"
    private static let birthdayPrefix = "birthday-"
    private static let horizonDays = 60
    private static let maxScheduled = 20
    private static let fireHour = 9

    struct Anniversary {
        let destinationID: UUID
        let placeName: String
        let yearsAgo: Int
        let fireDate: Date
    }

    struct Birthday {
        let yearsOld: Int
        let fireDate: Date
    }

    static func refresh(destinations: [Destination], baby: BabyProfile?) async {
        let memories = upcomingAnniversaries(for: destinations)
        let birthday = nextBirthday(for: baby?.birthDate)
        // Rien à planifier : on ne dérange pas l'utilisateur avec
        // une demande d'autorisation prématurée.
        guard !memories.isEmpty || birthday != nil else { return }

        let center = UNUserNotificationCenter.current()
        guard await ensureAuthorization(center: center) else { return }
        await removeOurPendingRequests(center: center)

        let name = baby?.name.nilIfBlank ?? "bébé"
        for memory in memories {
            await schedule(memoryOf: memory, babyName: name, center: center)
        }
        if let birthday {
            await schedule(birthday: birthday, babyName: name, center: center)
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

    /// Le prochain anniversaire du bébé (dans l'année à venir), avec l'âge fêté.
    static func nextBirthday(for birthDate: Date?) -> Birthday? {
        guard let birthDate, birthDate <= .now else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthDate)
        guard let next = calendar.nextDate(
            after: .now,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) else { return nil }
        let years = calendar.dateComponents([.year], from: birthDate, to: next).year ?? 1
        return Birthday(yearsOld: max(1, years), fireDate: next)
    }

    // MARK: - Planification

    private static func ensureAuthorization(center: UNUserNotificationCenter) async -> Bool {
        var settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            settings = await center.notificationSettings()
        }
        return settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    private static func removeOurPendingRequests(center: UNUserNotificationCenter) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter {
            $0.hasPrefix(memoryPrefix) || $0.hasPrefix(birthdayPrefix)
        }
        center.removePendingNotificationRequests(withIdentifiers: ours)
    }

    private static func schedule(
        memoryOf anniversary: Anniversary,
        babyName: String,
        center: UNUserNotificationCenter
    ) async {
        let title = anniversary.yearsAgo == 1
            ? "Il y a un an…"
            : "Il y a \(anniversary.yearsAgo) ans…"
        let body = "Vous étiez à \(anniversary.placeName) avec \(babyName). Ouvrez le journal pour revivre ce souvenir."
        await add(
            identifier: "\(memoryPrefix)\(anniversary.destinationID.uuidString)-\(anniversary.yearsAgo)",
            title: title,
            body: body,
            fireDate: anniversary.fireDate,
            center: center
        )
    }

    private static func schedule(
        birthday: Birthday,
        babyName: String,
        center: UNUserNotificationCenter
    ) async {
        let age = birthday.yearsOld == 1 ? "1 an" : "\(birthday.yearsOld) ans"
        await add(
            identifier: "\(birthdayPrefix)\(birthday.yearsOld)",
            title: "Joyeux anniversaire \(babyName) ! 🎂",
            body: "\(age) aujourd'hui ! Ouvrez Dinapp pour marquer cette grande journée d'une nouvelle aventure.",
            fireDate: birthday.fireDate,
            center: center
        )
    }

    /// Crée et enregistre une notification déclenchée à 9 h le jour donné.
    private static func add(
        identifier: String,
        title: String,
        body: String,
        fireDate: Date,
        center: UNUserNotificationCenter
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = fireHour
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        try? await center.add(request)
    }
}
