import SwiftUI

struct TripPlannerView: View {
    @StateObject private var vm = TripPlannerViewModel()
    @EnvironmentObject private var premium: PremiumState
    let skinType: FitzpatrickType
    var hasPhotosensitivity: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trip Planner")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.glowDarkText)
                        Text("UV forecast for your destination")
                            .font(.system(size: 15))
                            .foregroundColor(.glowDarkText.opacity(0.55))
                    }
                    Spacer()
                    if vm.tripPlan != nil {
                        Button(action: vm.reset) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.glowAmber)
                        }
                    }
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 28)

                if let plan = vm.tripPlan {
                    TripResultView(plan: plan, skinType: skinType, hasPhotosensitivity: hasPhotosensitivity)
                        .padding(.horizontal, 20)
                } else {
                    TripInputView(vm: vm, skinType: skinType)
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 120)
            }
        }
    }
}

// MARK: - Input

struct TripInputView: View {
    @ObservedObject var vm: TripPlannerViewModel
    let skinType: FitzpatrickType

    var body: some View {
        VStack(spacing: 16) {
            // Destination search
            VStack(alignment: .leading, spacing: 8) {
                Label("Destination", systemImage: "mappin.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.glowAmber.opacity(0.9))

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.glowDarkText.opacity(0.4))
                    TextField("", text: $vm.searchQuery, prompt: Text("Search city...").foregroundColor(.glowDarkText.opacity(0.3)))
                        .foregroundColor(.glowDarkText)
                        .autocorrectionDisabled()
                        .onChange(of: vm.searchQuery) { _ in vm.search() }
                    if vm.isSearching {
                        ProgressView().tint(.glowAmber).scaleEffect(0.8)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.glowDarkText.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.glowDarkText.opacity(0.12), lineWidth: 1))
                )

                if !vm.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(vm.searchResults) { location in
                            Button {
                                vm.selectDestination(location)
                            } label: {
                                HStack {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 12))
                                        .foregroundColor(.glowAmber)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.95))
                                        Text("\(location.admin1.map { "\($0), " } ?? "")\(location.country)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            if location.id != vm.searchResults.last?.id {
                                Divider().background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(red: 0.12, green: 0.10, blue: 0.06))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.glowAmber.opacity(0.25), lineWidth: 1))
                    )
                }
            }

            // Dates
            VStack(alignment: .leading, spacing: 8) {
                Label("Travel Dates", systemImage: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.glowAmber.opacity(0.9))

                HStack(spacing: 12) {
                    DatePickerCard(label: "Arrival", date: $vm.startDate, range: Date()...)
                    DatePickerCard(label: "Departure", date: $vm.endDate, range: vm.startDate.addingTimeInterval(86400)...)
                }
            }

            // Trip length note
            if vm.dateRangeValid {
                let days = Calendar.current.dateComponents([.day], from: vm.startDate, to: vm.endDate).day ?? 0
                if days > 16 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.glowAmber.opacity(0.7))
                        Text("Forecasts are available up to 16 days ahead. Showing first 16 days.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.glowDark.opacity(0.7))
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.glowDark.opacity(0.20)))
                }
            }

            // Build plan CTA
            Button {
                Task { await vm.buildPlan(skinType: skinType) }
            } label: {
                if vm.isLoadingPlan {
                    HStack(spacing: 10) {
                        ProgressView().tint(.glowDark)
                        Text("Building your plan...")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.glowDark)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.glowGold)
                    .cornerRadius(16)
                } else {
                    Label("Build My Trip Plan", systemImage: "airplane")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(vm.canPlan ? .glowDark : .glowDarkText.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(vm.canPlan ? Color.glowGold : Color.glowDarkText.opacity(0.07))
                        .cornerRadius(16)
                }
            }
            .disabled(!vm.canPlan || vm.isLoadingPlan)

            if let error = vm.error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.glowCoral)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct DatePickerCard: View {
    let label: String
    @Binding var date: Date
    let range: PartialRangeFrom<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.glowDark.opacity(0.65))
                .textCase(.uppercase)
            DatePicker("", selection: $date, in: range, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(.dark)
                .accentColor(.glowAmber)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.glowDark.opacity(0.20))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.glowDarkText.opacity(0.12), lineWidth: 1))
        )
    }
}

// MARK: - Results

struct TripResultView: View {
    let plan: TripPlan
    let skinType: FitzpatrickType
    var hasPhotosensitivity: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Trip summary card
            TripSummaryCard(plan: plan)

            if hasPhotosensitivity {
                PhotosensitivityProtectionCard()
            }

            // Per-day cards
            ForEach(plan.dailyForecasts) { day in
                TripDayCard(day: day, skinType: skinType, hasPhotosensitivity: hasPhotosensitivity)
            }
        }
    }
}

struct TripSummaryCard: View {
    let plan: TripPlan

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Destination + dates header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane.arrival")
                            .font(.system(size: 13))
                            .foregroundColor(.glowAmber)
                        Text(plan.destination.displayName)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.glowDarkText)
                    }
                    Text("\(dateFormatter.string(from: plan.startDate)) – \(dateFormatter.string(from: plan.endDate)) · \(plan.tripLength) days")
                        .font(.system(size: 13))
                        .foregroundColor(.glowDarkText.opacity(0.55))
                }
                Spacer()
            }
            .padding(20)

            Divider().background(Color.glowDarkText.opacity(0.08))

            // Stats row
            HStack(spacing: 0) {
                TripStatItem(label: "Avg UV", value: String(format: "%.1f", plan.averageUV))
                Divider().frame(height: 30).background(Color.glowDarkText.opacity(0.15))
                TripStatItem(label: "Peak UV", value: String(format: "%.0f", plan.peakUVDay?.maxUV ?? 0))
                Divider().frame(height: 30).background(Color.glowDarkText.opacity(0.15))
                TripStatItem(label: "Days", value: "\(plan.tripLength)")
            }
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.glowAmber.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.glowAmber.opacity(0.3), lineWidth: 1))
        )
    }
}

struct TripStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.glowDarkText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.glowDarkText.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }
}

struct TripDayCard: View {
    let day: DailyForecast
    let skinType: FitzpatrickType
    var hasPhotosensitivity: Bool = false

    private var burnLimit: Int {
        skinType.safeExposureMinutes(uvIndex: day.maxUV)
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()

    var body: some View {
        HStack(spacing: 16) {
            // Date column
            VStack(spacing: 4) {
                Text(day.date, formatter: weekdayFormatter)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.glowDarkText)
                Text(day.date, formatter: dayFormatter)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.glowDarkText)
                Text(day.date, formatter: monthFormatter)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.glowDark.opacity(0.6))
            }
            .frame(width: 44)

            Divider().frame(height: 60).background(Color.glowDarkText.opacity(0.1))

            // UV + exposure info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("UV \(String(format: "%.0f", day.maxUV))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(Color.uvColor(for: day.maxUV))
                    Text(UVCategory(uvIndex: day.maxUV).label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.glowDark.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.uvColor(for: day.maxUV).opacity(0.15))
                        .cornerRadius(6)
                }

                HStack(spacing: 16) {
                    if hasPhotosensitivity {
                        Label("Avoid direct sun", systemImage: "shield.lefthalf.filled")
                            .font(.system(size: 12))
                            .foregroundColor(.glowAmber.opacity(0.85))
                    } else {
                        if let window = day.tanningWindow {
                            Label("\(timeFormatter.string(from: window.start))–\(timeFormatter.string(from: window.end))", systemImage: "sun.and.horizon.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.glowDark.opacity(0.8))
                        }
                        if burnLimit > 0 {
                            Label("\(burnLimit) min limit", systemImage: "timer")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.glowDark.opacity(0.8))
                        }
                    }
                }
            }

            Spacer()

            // Cloud cover
            VStack(spacing: 2) {
                Image(systemName: day.averageCloudCover > 50 ? "cloud.fill" : "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.glowDark.opacity(0.6))
                Text("\(day.averageCloudCover)%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.glowDark.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.glowDark.opacity(0.20))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.uvColor(for: day.maxUV).opacity(0.2), lineWidth: 1))
        )
    }

    private var weekdayFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }
    private var dayFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }
    private var monthFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f
    }
}
