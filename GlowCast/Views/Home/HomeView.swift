import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject private var premium: PremiumState
    @State private var selectedTab: Tab = .home
    @State private var showPaywall = false

    enum Tab { case home, forecast, timer, spf }

    var body: some View {
        ZStack {
            GlowGradient(uvIndex: vm.currentUV)

            if vm.isLoading {
                LoadingView()
            } else {
                TabView(selection: $selectedTab) {
                    MainDashboardView(vm: vm)
                        .tag(Tab.home)

                    if premium.isPremium {
                        ForecastView(forecast: vm.threeDayForecast, today: vm.todayForecast)
                            .tag(Tab.forecast)
                    } else {
                        LockedFeatureView(
                            icon: "chart.bar.fill",
                            title: "3-Day UV Forecast",
                            onUnlock: { showPaywall = true }
                        )
                        .tag(Tab.forecast)
                    }

                    TanTimerView(vm: vm)
                        .tag(Tab.timer)

                    if premium.isPremium {
                        SPFCalculatorView(skinType: vm.skinType, uvIndex: vm.currentUV)
                            .tag(Tab.spf)
                    } else {
                        LockedFeatureView(
                            icon: "drop.fill",
                            title: "Advanced SPF Calculator",
                            onUnlock: { showPaywall = true }
                        )
                        .tag(Tab.spf)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Custom tab bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onSubscribe: {
                    PremiumState.shared.unlock()
                    showPaywall = false
                },
                onRestore: {
                    PremiumState.shared.unlock()
                    showPaywall = false
                },
                onDismiss: { showPaywall = false }
            )
        }
    }
}

struct LockedFeatureView: View {
    let icon: String
    let title: String
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.glowAmber.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.glowAmber.opacity(0.5))
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.glowGold)
                    .offset(x: 22, y: 22)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                Text("Upgrade to GlowCast Premium\nto unlock this feature.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }

            Button(action: onUnlock) {
                Text("Unlock Premium")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.glowDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.glowGold)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView: View {
    @State private var angle: Double = 0
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.glowGold, lineWidth: 3)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(angle))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        angle = 360
                    }
                }
            Text("Finding your sun...")
                .font(.system(size: 16))
                .foregroundColor(.glowCream.opacity(0.7))
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: HomeView.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "sun.max.fill", label: "Today", tab: .home, selectedTab: $selectedTab)
            TabBarItem(icon: "chart.bar.fill", label: "Forecast", tab: .forecast, selectedTab: $selectedTab)
            TabBarItem(icon: "timer", label: "Timer", tab: .timer, selectedTab: $selectedTab)
            TabBarItem(icon: "drop.fill", label: "SPF", tab: .spf, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.glowDark.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let tab: HomeView.Tab
    @Binding var selectedTab: HomeView.Tab

    var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .glowAmber : .white.opacity(0.35))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .glowAmber : .white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
