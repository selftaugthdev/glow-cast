import SwiftUI

struct ForecastView: View {
    let forecast: [DailyForecast]
    let today: DailyForecast?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("UV Forecast")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.glowDarkText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                Spacer().frame(height: 24)

                // Hourly bar chart for today
                if let today {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today — Hourly")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.glowAmber.opacity(0.9))
                            .padding(.horizontal, 24)

                        UVBarChart(entries: today.hourly, tanningWindow: today.tanningWindow)
                            .frame(height: 160)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.glowDark.opacity(0.90))
                    )
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 20)

                // 3-day strip
                VStack(spacing: 12) {
                    Text("3-Day Overview")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.glowAmber.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    ForEach(forecast) { day in
                        DayForecastRow(day: day)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 120)
            }
        }
    }
}

struct UVBarChart: View {
    let entries: [HourlyUVEntry]
    let tanningWindow: (start: Date, end: Date)?

    private var dayEntries: [HourlyUVEntry] {
        entries.filter { $0.hour >= 6 && $0.hour <= 20 }
    }

    private var maxUV: Double {
        dayEntries.map(\.uvIndex).max() ?? 1
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(dayEntries) { entry in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(entry))
                            .frame(
                                width: max(4, (geo.size.width - CGFloat(dayEntries.count) * 4) / CGFloat(dayEntries.count)),
                                height: max(4, CGFloat(entry.uvIndex / maxUV) * (geo.size.height - 24))
                            )
                            .overlay(
                                isTanningWindow(entry) ?
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.glowGold, lineWidth: 1.5) : nil
                            )

                        if entry.hour % 3 == 0 {
                            Text("\(entry.hour)")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Text("").font(.system(size: 9))
                        }
                    }
                }
            }
        }
    }

    private func barColor(_ entry: HourlyUVEntry) -> Color {
        isTanningWindow(entry)
            ? Color.uvColor(for: entry.uvIndex).opacity(0.9)
            : Color.uvColor(for: entry.uvIndex).opacity(0.4)
    }

    private func isTanningWindow(_ entry: HourlyUVEntry) -> Bool {
        guard let window = tanningWindow else { return false }
        return entry.time >= window.start && entry.time <= window.end
    }
}

struct DayForecastRow: View {
    let day: DailyForecast

    var body: some View {
        HStack {
            Text(day.dayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, alignment: .leading)

            Spacer()

            // Mini UV bar
            UVMiniBar(uvIndex: day.maxUV)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("UV \(String(format: "%.0f", day.maxUV))")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color.uvColor(for: day.maxUV))
                if let window = day.tanningWindow {
                    Text(shortTimeRange(window.start, window.end))
                        .font(.system(size: 11))
                        .foregroundColor(.glowAmber.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.glowDark.opacity(0.90))
        )
    }

    private func shortTimeRange(_ start: Date, _ end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "ha"
        return "\(fmt.string(from: start))–\(fmt.string(from: end))"
    }
}

struct UVMiniBar: View {
    let uvIndex: Double
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.15))
                .frame(width: 80, height: 8)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.uvColor(for: uvIndex))
                .frame(width: min(80, CGFloat(uvIndex / 12.0) * 80), height: 8)
        }
    }
}
