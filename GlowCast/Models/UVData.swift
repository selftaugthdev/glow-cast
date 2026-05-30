import Foundation

struct HourlyUVEntry: Identifiable {
    let id = UUID()
    let hour: Int
    let time: Date
    let uvIndex: Double
    let cloudCover: Double

    var isTanningWindow: Bool {
        uvIndex >= 3 && cloudCover < 60
    }

    var uvCategory: UVCategory {
        UVCategory(uvIndex: uvIndex)
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let maxUV: Double
    let sunrise: Date
    let sunset: Date
    let hourly: [HourlyUVEntry]

    var tanningWindow: (start: Date, end: Date)? {
        let validHours = hourly.filter { entry in
            entry.isTanningWindow &&
            entry.time >= sunrise &&
            entry.time <= sunset
        }
        guard let first = validHours.first, let last = validHours.last else { return nil }
        return (first.time, last.time)
    }

    var averageCloudCover: Int {
        let daytime = hourly.filter { $0.hour >= 8 && $0.hour <= 20 }
        guard !daytime.isEmpty else { return 0 }
        return Int(daytime.map(\.cloudCover).reduce(0, +) / Double(daytime.count))
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

enum UVCategory {
    case low, moderate, high, veryHigh, extreme

    init(uvIndex: Double) {
        switch uvIndex {
        case ..<3:   self = .low
        case 3..<6:  self = .moderate
        case 6..<8:  self = .high
        case 8..<11: self = .veryHigh
        default:     self = .extreme
        }
    }

    var label: String {
        switch self {
        case .low:      return "Low"
        case .moderate: return "Moderate"
        case .high:     return "High"
        case .veryHigh: return "Very High"
        case .extreme:  return "Extreme"
        }
    }

    var hexColor: String {
        switch self {
        case .low:      return "#4CAF50"
        case .moderate: return "#FFEB3B"
        case .high:     return "#FF9800"
        case .veryHigh: return "#F44336"
        case .extreme:  return "#9C27B0"
        }
    }
}

struct OpenMeteoResponse: Decodable {
    let hourly: HourlyData
    let daily: DailyData

    struct HourlyData: Decodable {
        let time: [String]
        let uv_index: [Double]
        let cloud_cover: [Double]
    }

    struct DailyData: Decodable {
        let time: [String]
        let uv_index_max: [Double]
        let sunrise: [String]
        let sunset: [String]
    }
}
