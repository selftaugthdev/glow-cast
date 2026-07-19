import UIKit
import Vision

enum ScanError: Error {
    case imageConversionFailed
    case noFaceDetected
    case analysisFailed
}

/// Estimates Fitzpatrick skin type entirely on-device: detects the face with
/// Vision, samples forehead/cheek pixels, and converts the average color to
/// an Individual Typology Angle (ITA°) — the standard dermatological measure
/// used to classify skin phototype from colorimetric data.
final class SkinToneService {
    func analyzeSkinType(image: UIImage) async throws -> FitzpatrickType {
        guard let cgImage = image.cgImage else {
            throw ScanError.imageConversionFailed
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        )
        do {
            try handler.perform([request])
        } catch {
            throw ScanError.analysisFailed
        }

        guard let face = request.results?.first else {
            throw ScanError.noFaceDetected
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let box = face.boundingBox
        // Vision's boundingBox is normalized with origin at bottom-left; CGImage pixel data is top-left.
        let faceRect = CGRect(
            x: box.minX * width,
            y: (1 - box.maxY) * height,
            width: box.width * width,
            height: box.height * height
        )

        guard let samples = samplePixels(from: cgImage, faceRect: faceRect), !samples.isEmpty else {
            throw ScanError.analysisFailed
        }

        let averageColor = average(samples)
        let ita = individualTypologyAngle(for: averageColor)
        return FitzpatrickType.from(ita: ita)
    }

    // MARK: - Pixel sampling

    private func samplePixels(from cgImage: CGImage, faceRect: CGRect) -> [(r: Double, g: Double, b: Double)]? {
        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data)
        else { return nil }

        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 3 else { return nil }
        let dataLength = CFDataGetLength(data)

        // Forehead + both cheeks, as proportions of the face bounding box — avoids
        // eyes, brows, nostrils, and mouth without needing full landmark detection.
        let patches: [CGRect] = [
            proportionalRect(in: faceRect, x: 0.35, y: 0.12, w: 0.30, h: 0.14), // forehead
            proportionalRect(in: faceRect, x: 0.12, y: 0.50, w: 0.20, h: 0.16), // left cheek
            proportionalRect(in: faceRect, x: 0.68, y: 0.50, w: 0.20, h: 0.16)  // right cheek
        ]

        var samples: [(r: Double, g: Double, b: Double)] = []
        for patch in patches {
            let minX = max(0, Int(patch.minX))
            let maxX = min(cgImage.width - 1, Int(patch.maxX))
            let minY = max(0, Int(patch.minY))
            let maxY = min(cgImage.height - 1, Int(patch.maxY))
            guard minX < maxX, minY < maxY else { continue }

            // Stride through each patch rather than reading every pixel — plenty of signal, far less work.
            let strideX = max(1, (maxX - minX) / 12)
            let strideY = max(1, (maxY - minY) / 12)

            for y in stride(from: minY, to: maxY, by: strideY) {
                for x in stride(from: minX, to: maxX, by: strideX) {
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    guard offset + 2 < dataLength else { continue }
                    let r = Double(bytes[offset]) / 255.0
                    let g = Double(bytes[offset + 1]) / 255.0
                    let b = Double(bytes[offset + 2]) / 255.0
                    // Skip near-black/near-white outliers — shadows, hair, specular highlights.
                    let luma = 0.299 * r + 0.587 * g + 0.114 * b
                    guard luma > 0.08, luma < 0.95 else { continue }
                    samples.append((r, g, b))
                }
            }
        }
        return samples
    }

    private func proportionalRect(in rect: CGRect, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGRect {
        CGRect(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height, width: w * rect.width, height: h * rect.height)
    }

    private func average(_ samples: [(r: Double, g: Double, b: Double)]) -> (r: Double, g: Double, b: Double) {
        let count = Double(samples.count)
        let r = samples.reduce(0) { $0 + $1.r } / count
        let g = samples.reduce(0) { $0 + $1.g } / count
        let b = samples.reduce(0) { $0 + $1.b } / count
        return (r, g, b)
    }

    // MARK: - Colorimetry (sRGB -> CIE L*a*b* -> Individual Typology Angle)

    private func individualTypologyAngle(for color: (r: Double, g: Double, b: Double)) -> Double {
        let lab = labComponents(for: color)
        return atan2(lab.l - 50, lab.b) * 180 / .pi
    }

    private func labComponents(for color: (r: Double, g: Double, b: Double)) -> (l: Double, a: Double, b: Double) {
        func linearize(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let r = linearize(color.r)
        let g = linearize(color.g)
        let b = linearize(color.b)

        // sRGB -> XYZ (D65), then normalized by the D65 white point.
        let x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047
        let y = (r * 0.2126729 + g * 0.7151522 + b * 0.0721750) / 1.00000
        let z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883

        func f(_ t: Double) -> Double {
            t > 0.008856 ? cbrt(t) : (7.787 * t + 16.0 / 116.0)
        }
        let fx = f(x), fy = f(y), fz = f(z)

        let l = 116 * fy - 16
        let a = 500 * (fx - fy)
        let bLab = 200 * (fy - fz)
        return (l, a, bLab)
    }
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
