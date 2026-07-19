import SwiftUI

@main
struct TanCastApp: App {
    @StateObject private var premium = PremiumState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(premium)
        }
    }
}
