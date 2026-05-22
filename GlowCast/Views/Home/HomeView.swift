import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var selectedTab: Tab = .home

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

                    ForecastView(forecast: vm.threeDayForecast, today: vm.todayForecast)
                        .tag(Tab.forecast)

                    TanTimerView(vm: vm)
                        .tag(Tab.timer)

                    SPFCalculatorView(skinType: vm.skinType, uvIndex: vm.currentUV)
                        .tag(Tab.spf)
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
