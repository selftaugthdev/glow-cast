import UIKit

/// Calls the TanCast skin-scan Cloudflare Worker proxy instead of Anthropic
/// directly — the real Anthropic API key lives only on the Worker, never in
/// this app. The app authenticates to the proxy with a separate, narrower
/// token (Secrets.skinScanProxyToken) that only unlocks this one endpoint.
final class ClaudeVisionProxyService {
    private let proxyToken = Secrets.skinScanProxyToken
    private let endpoint = URL(string: "https://tancast-skin-scan-proxy.truthdare.workers.dev/scan")!

    func analyzeSkinType(image: UIImage) async throws -> FitzpatrickType {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ScanError.imageConversionFailed
        }
        let base64 = imageData.base64EncodedString()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(proxyToken, forHTTPHeaderField: "X-Proxy-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["image": base64])

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429 { throw ScanError.rateLimited }
            guard (200..<300).contains(http.statusCode) else { throw ScanError.invalidResponse }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let numeral = json["result"] as? String
        else { throw ScanError.invalidResponse }

        // A refusal or unexpected reply must surface as an error, not a default type —
        // the caller falls back to the manual picker.
        guard let type = FitzpatrickType.from(romanNumeral: numeral.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw ScanError.invalidResponse
        }
        return type
    }
}
