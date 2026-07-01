import SwiftUI

/// Holds the app's chosen display language and applies it at runtime so the
/// user can switch between English, French, and Spanish inside the app —
/// independent of the iOS system language.
@MainActor
final class LanguageManager: ObservableObject {

    enum Language: String, CaseIterable, Identifiable {
        case system, en, fr, es
        var id: String { rawValue }

        /// Name shown in the picker, written in that language.
        var displayName: String {
            switch self {
            case .system: return String(localized: "Follow system")
            case .en: return "English"
            case .fr: return "Français"
            case .es: return "Español"
            }
        }

        var flag: String {
            switch self {
            case .system: return "🌐"
            case .en: return "🇬🇧"
            case .fr: return "🇫🇷"
            case .es: return "🇪🇸"
            }
        }

        /// The `.lproj` code to load, or nil to follow the system language.
        var code: String? { self == .system ? nil : rawValue }
    }

    @Published private(set) var current: Language

    private static let storageKey = "app_language"

    init() {
        if ProcessInfo.processInfo.arguments.contains("UITEST_RESET") {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        current = saved.flatMap(Language.init(rawValue:)) ?? .system
        apply(current)
    }

    /// The locale to inject into the SwiftUI environment for date/number
    /// formatting so it matches the chosen strings language.
    var locale: Locale {
        if let code = current.code { return Locale(identifier: code) }
        return Locale.autoupdatingCurrent
    }

    func set(_ language: Language) {
        guard language != current else { return }
        current = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        apply(language)
    }

    private func apply(_ language: Language) {
        Bundle.setLanguage(language.code)
    }
}
