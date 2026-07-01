import SwiftUI

@main
struct TripForgeApp: App {
    @StateObject private var store = TripStore()
    @StateObject private var language = LanguageManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(language)
                .environment(\.locale, language.locale)
                .id(language.current)
                .preferredColorScheme(.dark)
                .tint(Brand.teal)
        }
    }
}
