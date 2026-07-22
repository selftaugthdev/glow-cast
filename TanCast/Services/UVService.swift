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

    // Finds the hourly entry closest to "now" in absolute time, rather than
    // comparing calendar-hour components — the latter is device-timezone-
    // dependent and silently wrong whenever the device isn't in the same
    // timezone as the forecast location (e.g. simulating a location on the
    // other side of the world from the device's real system timezone).
    private func currentUVIndex(from forecast: DailyForecast?) -> Double {
        guard let forecast, !forecast.hourly.isEmpty else { return 0 }
        let now = Date()
        let closest = forecast.hourly.min {
            abs($0.time.timeIntervalSince(now)) < abs($1.time.timeIntervalSince(now))
        }
        return closest?.uvIndex ?? 0
    }

    private func parse(response: OpenMeteoResponse) -> [DailyForecast] {
        // Open-Meteo returns wall-clock times local to the *requested
        // coordinates* (via timezone=auto), not the device's own timezone —
        // parsing them without this offset silently misinterprets every
        // timestamp whenever the device and the forecast location differ.
        let locationTimeZone = TimeZone(secondsFromGMT: response.utc_offset_seconds) ?? .current
        var locationCalendar = Calendar(identifier: .gregorian)
        locationCalendar.timeZone = locationTimeZone

        let isoDateTime = DateFormatter()
        isoDateTime.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoDateTime.locale = Locale(identifier: "en_US_POSIX")
        isoDateTime.timeZone = locationTimeZone

        let isoDate = DateFormatter()
        isoDate.dateFormat = "yyyy-MM-dd"
        isoDate.locale = Locale(identifier: "en_US_POSIX")
        isoDate.timeZone = locationTimeZone

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
                hour: locationCalendar.component(.hour, from: date),
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
                hourly: hourly.sorted { $0.time < $1.time },
                timeZone: locationTimeZone
            )
        }.sorted { $0.date < $1.date }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
