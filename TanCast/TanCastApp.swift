import SwiftUI
import FirebaseCore

@main
struct TanCastApp: App {
    @StateObject private var premium = PremiumState.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(premium)
        }
    }
}
