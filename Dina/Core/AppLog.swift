import Foundation
import os

/// Loggers centralisés : visibles dans Console.app et conservés
/// en production, contrairement aux `print`.
enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.alexandre.dina"

    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let sharing = Logger(subsystem: subsystem, category: "sharing")
    static let export = Logger(subsystem: subsystem, category: "export")
}
