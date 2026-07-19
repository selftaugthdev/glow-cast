import Foundation

struct GeoLocation: Identifiable, Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?

    var displayName: String {
        if let region = admin1 {
            return "\(name), \(region)"
        }
        return "\(name), \(country)"
    }
}

struct GeocodingResponse: Decodable {
    let results: [GeoLocation]?
}

struct TripPlan: Identifiable {
    let id = UUID()
    let destination: GeoLocation
    let startDate: Date
    let endDate: Date
    var dailyForecasts: [DailyForecast]

    var peakUVDay: DailyForecast? {
        dailyForecasts.max(by: { $0.maxUV < $1.maxUV })
    }

    var averageUV: Double {
        guard !dailyForecasts.isEmpty else { return 0 }
        return dailyForecasts.map(\.maxUV).reduce(0, +) / Double(dailyForecasts.count)
    }

    var tripLength: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}
