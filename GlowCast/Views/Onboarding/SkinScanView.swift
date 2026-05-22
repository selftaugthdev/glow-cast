import SwiftUI
import AVFoundation

struct SkinScanView: View {
    let onCapture: (UIImage) -> Void
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var scanLineOffset: CGFloat = -120
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("AI Skin Scan")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.glowGold)

                Text("Personalized tanning just for you")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 8)

                Spacer().frame(height: 48)

                ZStack {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 260, height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.glowAmber, lineWidth: 2)
                            )

                        if isAnalyzing {
                            // Scanning line
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, Color.glowAmber.opacity(0.8), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 260, height: 3)
                                .offset(y: scanLineOffset)
                                .animation(
                                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                    value: scanLineOffset
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24))

                            Color.glowAmber.opacity(0.08)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    } else {
                        // Face frame placeholder
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.glowAmber.opacity(0.4), lineWidth: 2)
                            .frame(width: 260, height: 320)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                Image(systemName: "person.crop.rectangle")
                                    .font(.system(size: 64))
                                    .foregroundColor(.glowAmber.opacity(0.3))
                            )
                    }

                    // Corner brackets
                    CornerBrackets()
                        .frame(width: 260, height: 320)
                }

                Spacer().frame(height: 24)

                Text("Your photo is analyzed instantly and never stored.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                if isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.glowAmber)
                        Text("Analyzing skin tone...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.glowAmber)
                    }
                    .padding(.bottom, 60)
                } else {
                    Button(action: { showCamera = true }) {
                        Label("Scan My Skin", systemImage: "camera.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage, onCapture: handleCapture)
        }
    }

    private func handleCapture(_ image: UIImage) {
        capturedImage = image
        isAnalyzing = true
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            scanLineOffset = 120
        }
        onCapture(image)
    }
}

struct CornerBrackets: View {
    let size: CGFloat = 20
    let thickness: CGFloat = 3

    var body: some View {
        ZStack {
            // Top-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: size))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: size, y: 0))
            }
            .stroke(Color.glowAmber, lineWidth: thickness)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Top-right
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: size, y: 0))
                p.addLine(to: CGPoint(x: size, y: size))
            }
            .stroke(Color.glowAmber, lineWidth: thickness)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 0, y: size))
                p.addLine(to: CGPoint(x: size, y: size))
            }
            .stroke(Color.glowAmber, lineWidth: thickness)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: size, y: 0))
                p.addLine(to: CGPoint(x: size, y: size))
                p.addLine(to: CGPoint(x: 0, y: size))
            }
            .stroke(Color.glowAmber, lineWidth: thickness)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
                parent.onCapture(img)
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
