import UIKit

enum ScanError: Error {
    case imageConversionFailed
    case networkError(Error)
    case invalidResponse
    case rateLimited
}

final class ClaudeVisionService {
    private let apiKey = Secrets.anthropicAPIKey
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func analyzeSkinType(image: UIImage) async throws -> FitzpatrickType {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ScanError.imageConversionFailed
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 10,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64
                        ]
                    ],
                    [
                        "type": "text",
                        "text": "Look at the skin tone in this photo. Classify it as Fitzpatrick scale I, II, III, IV, V, or VI. Reply with only the Roman numeral, nothing else."
                    ]
                ]
            ]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 429 { throw ScanError.rateLimited }
                guard (200..<300).contains(http.statusCode) else { throw ScanError.invalidResponse }
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = (json["content"] as? [[String: Any]])?.first,
                  let text = content["text"] as? String
            else { throw ScanError.invalidResponse }

            let numeral = text.trimmingCharacters(in: .whitespacesAndNewlines)
            // A refusal or unexpected reply must surface as an error, not a default type —
            // the caller falls back to the manual picker.
            guard let type = FitzpatrickType.from(romanNumeral: numeral) else {
                throw ScanError.invalidResponse
            }
            return type
        } catch let e as ScanError {
            throw e
        } catch {
            throw ScanError.networkError(error)
        }
    }
}
