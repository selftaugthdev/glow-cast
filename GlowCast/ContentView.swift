import SwiftUI

struct ContentView: View {
    @State private var onboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some View {
        if onboardingComplete {
            HomeView()
        } else {
            OnboardingView {
                withAnimation { onboardingComplete = true }
            }
        }
    }
}
