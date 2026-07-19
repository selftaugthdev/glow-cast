import Foundation

final class TripUVService {
    private let session = URLSession.shared

    private let isoDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func fetch(latitude: Double, longitude: Double, startDate: Date, endDate: Date) async throws -> [DailyForecast] {
        let start = isoDate.string(from: startDate)
        let end = isoDate.string(from: endDate)
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)&longitude=\(longitude)"
            + "&hourly=uv_index,cloud_cover"
            + "&daily=uv_index_max,sunrise,sunset"
            + "&timezone=auto"
            + "&start_date=\(start)&end_date=\(end)"

        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return parse(response: response)
    }

    private func parse(response: OpenMeteoResponse) -> [DailyForecast] {
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
