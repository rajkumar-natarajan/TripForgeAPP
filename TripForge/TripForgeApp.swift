import SwiftUI

@main
struct TripForgeApp: App {
    @StateObject private var store = TripStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Brand.teal)
        }
    }
}
