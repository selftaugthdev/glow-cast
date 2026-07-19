import Foundation

final class GeocodingService {
    private let session = URLSession.shared

    func search(query: String) async throws -> [GeoLocation] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=6&language=en&format=json"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        return response.results ?? []
    }
}
