import UIKit
import Vision

enum ScanError: Error {
    case imageConversionFailed
    case noFaceDetected
    case analysisFailed
    case rateLimited
    case invalidResponse
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

        // Render into a buffer we fully control: upright orientation and explicit
        // RGBA8/sRGB layout. Vision's boundingBox is reported in the "upright" frame
        // (it accounts for the orientation we passed above), but the raw CGImage's
        // pixel buffer may still be physically rotated/mirrored relative to that —
        // front-camera selfies commonly carry EXIF orientation rather than pre-rotated
        // pixels. Sampling straight from cgImage.dataProvider (as a previous version
        // of this code did) mapped the box onto the wrong axes and also assumed an
        // unverified RGBA byte order, both of which this buffer sidesteps.
        guard let buffer = RGBABuffer(image: image) else {
            throw ScanError.analysisFailed
        }

        let width = CGFloat(buffer.width)
        let height = CGFloat(buffer.height)
        let box = face.boundingBox
        // Vision's boundingBox is normalized with origin at bottom-left; pixel data is top-left.
        let faceRect = CGRect(
            x: box.minX * width,
            y: (1 - box.maxY) * height,
            width: box.width * width,
            height: box.height * height
        )

        guard let samples = samplePixels(from: buffer, faceRect: faceRect), !samples.isEmpty else {
            throw ScanError.analysisFailed
        }

        let averageColor = average(samples)
        let ita = individualTypologyAngle(for: averageColor)
        let result = FitzpatrickType.from(ita: ita)

        #if DEBUG
        let lumas = samples.map { 0.299 * $0.r + 0.587 * $0.g + 0.114 * $0.b }
        let minLuma = lumas.min() ?? 0
        let maxLuma = lumas.max() ?? 0
        print("""
        [SkinToneService] image size=\(image.size) scale=\(image.scale) orientation=\(image.imageOrientation.rawValue)
        [SkinToneService] buffer=\(buffer.width)x\(buffer.height) faceBox(norm)=\(box) faceRect(px)=\(faceRect)
        [SkinToneService] samples=\(samples.count) avgRGB=(\(Int(averageColor.r * 255)), \(Int(averageColor.g * 255)), \(Int(averageColor.b * 255))) lumaRange=(\(Int(minLuma * 255))-\(Int(maxLuma * 255)))
        [SkinToneService] ITA=\(ita) -> \(result.displayName)
        """)
        #endif

        return result
    }

    // MARK: - Pixel sampling

    private func samplePixels(from buffer: RGBABuffer, faceRect: CGRect) -> [(r: Double, g: Double, b: Double)]? {
        // A single patch dead-center in the face box — squarely between the eyes
        // (above) and mouth (below), well clear of the box's outer edges (ears,
        // jaw shadow) and top (hairline/brows). Deliberately conservative: a
        // multi-region approach (forehead + cheeks) is more thorough in theory,
        // but each small region is sensitive to exactly where Vision's box edges
        // fall, and a mis-targeted patch (e.g. landing on eyebrow shadow) silently
        // pollutes the average with no way to detect it.
        let patches: [CGRect] = [
            proportionalRect(in: faceRect, x: 0.28, y: 0.38, w: 0.44, h: 0.26)
        ]

        var samples: [(r: Double, g: Double, b: Double)] = []
        for patch in patches {
            let minX = max(0, Int(patch.minX))
            let maxX = min(buffer.width - 1, Int(patch.maxX))
            let minY = max(0, Int(patch.minY))
            let maxY = min(buffer.height - 1, Int(patch.maxY))
            guard minX < maxX, minY < maxY else { continue }

            // Stride through each patch rather than reading every pixel — plenty of signal, far less work.
            let strideX = max(1, (maxX - minX) / 12)
            let strideY = max(1, (maxY - minY) / 12)

            for y in stride(from: minY, to: maxY, by: strideY) {
                for x in stride(from: minX, to: maxX, by: strideX) {
                    guard let pixel = buffer.pixel(x: x, y: y) else { continue }
                    // Skip near-black/near-white outliers — shadows, hair, specular highlights.
                    let luma = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b
                    guard luma > 0.08, luma < 0.95 else { continue }
                    samples.append(pixel)
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

/// A pixel buffer rendered from a UIImage in a known, explicit format: upright
/// orientation, RGBA8, sRGB color space — regardless of the source image's own
/// EXIF orientation, byte order, or color space.
private struct RGBABuffer {
    let pixels: [UInt8]
    let width: Int
    let height: Int
    let bytesPerRow: Int

    init?(image: UIImage) {
        let width = max(1, Int(image.size.width * image.scale))
        let height = max(1, Int(image.size.height * image.scale))
        let bytesPerRow = width * 4

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }

        // UIImage.draw(in:) respects imageOrientation and renders upright into
        // whichever context is current — pushing our own context here means the
        // resulting buffer's pixel axes always match the visual image.
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()

        guard let data = context.data else { return nil }
        self.pixels = [UInt8](UnsafeBufferPointer(
            start: data.assumingMemoryBound(to: UInt8.self),
            count: bytesPerRow * height
        ))
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
    }

    func pixel(x: Int, y: Int) -> (r: Double, g: Double, b: Double)? {
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        let offset = y * bytesPerRow + x * 4
        guard offset + 2 < pixels.count else { return nil }
        return (
            Double(pixels[offset]) / 255.0,
            Double(pixels[offset + 1]) / 255.0,
            Double(pixels[offset + 2]) / 255.0
        )
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
