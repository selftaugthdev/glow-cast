import Foundation
import CoreLocation

@MainActor
final class UVService: ObservableObject {
    @Published var todayForecast: DailyForecast?
    @Published var threeDayForecast: [DailyForecast] = []
    @Published var currentUV: Double = 0
    @Published var isLoading = false
    @Published var error: String?

    private let session = URLSession.shared

    func fetch(for location: CLLocation) async {
        isLoading = true
        error = nil
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&hourly=uv_index,cloud_cover"
            + "&daily=uv_index_max,sunrise,sunset"
            + "&timezone=auto"
            + "&forecast_days=3"

        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let forecasts = parse(response: response)
            self.threeDayForecast = forecasts
            self.todayForecast = forecasts.first
            self.currentUV = currentUVIndex(from: forecasts.first)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func currentUVIndex(from forecast: DailyForecast?) -> Double {
        guard let forecast else { return 0 }
        let now = Date()
        let cal = Calendar.current
        let currentHour = cal.component(.hour, from: now)
        return forecast.hourly.first { cal.component(.hour, from: $0.time) == currentHour }?.uvIndex ?? 0
    }

    private func parse(response: OpenMeteoResponse) -> [DailyForecast] {
        let isoDateTime = DateFormatter()
        isoDateTime.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoDateTime.locale = Locale(identifier: "en_US_POSIX")

        let isoDate = DateFormatter()
        isoDate.dateFormat = "yyyy-MM-dd"
        isoDate.locale = Locale(identifier: "en_US_POSIX")

        var dailyMap: [String: (maxUV: Double, sunrise: Date, sunset: Date)] = [:]
        for (i, dateStr) in response.daily.time.enumerated() {
            guard i < response.daily.uv_index_max.count,
                  let date = isoDate.date(from: dateStr),
                  let sunriseDate = isoDateTime.date(from: response.daily.sunrise[safe: i] ?? ""),
                  let sunsetDate = isoDateTime.date(from: response.daily.sunset[safe: i] ?? "")
            else { continue }
            let key = isoDate.string(from: date)
            dailyMap[key] = (response.daily.uv_index_max[i], sunriseDate, sunsetDate)
        }

        var hourlyByDay: [String: [HourlyUVEntry]] = [:]
        for (i, timeStr) in response.hourly.time.enumerated() {
            guard let date = isoDateTime.date(from: timeStr),
                  i < response.hourly.uv_index.count,
                  i < response.hourly.cloud_cover.count
            else { continue }
            let key = isoDate.string(from: date)
            let entry = HourlyUVEntry(
                hour: Calendar.current.component(.hour, from: date),
                time: date,
                uvIndex: response.hourly.uv_index[i],
                cloudCover: response.hourly.cloud_cover[i]
            )
            hourlyByDay[key, default: []].append(entry)
        }

        return dailyMap.compactMap { (key, info) -> DailyForecast? in
            guard let date = isoDate.date(from: key) else { return nil }
            let hourly = hourlyByDay[key] ?? []
            return DailyForecast(
                date: date,
                maxUV: info.maxUV,
                sunrise: info.sunrise,
                sunset: info.sunset,
                hourly: hourly.sorted { $0.time < $1.time }
            )
        }.sorted { $0.date < $1.date }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
