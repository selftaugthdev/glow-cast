import SwiftUI

struct TanTimerView: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("Tan Timer")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                Text("Safe tanning for your skin type")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                Spacer().frame(height: 48)

                // Ring timer
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 12)
                        .frame(width: 240, height: 240)

                    Circle()
                        .trim(from: 0, to: vm.sessionActive ? vm.sessionProgress : 0)
                        .stroke(
                            LinearGradient(
                                colors: [Color.glowAmber, Color.glowCoral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: vm.sessionProgress)

                    VStack(spacing: 4) {
                        if vm.sessionComplete {
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.glowAmber)
                                Text("Done!")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.white)
                                Text("Apply SPF or find shade")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        } else if vm.sessionActive {
                            Text(timerString)
                                .font(.system(size: 52, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("remaining")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        } else if vm.currentUV < 1 {
                            VStack(spacing: 6) {
                                Text("No UV")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Come back when the sun is out")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.35))
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            VStack(spacing: 6) {
                                Text(verbatim: "\(vm.safeMinutes)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("minutes")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.55))
                                Text("for \(vm.skinType.displayName) at UV \(String(format: "%.0f", vm.currentUV))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.glowAmber.opacity(0.8))
                            }
                        }
                    }
                }

                Spacer().frame(height: 48)

                if vm.sessionComplete {
                    Button {
                        vm.stopSession()
                    } label: {
                        Text("Start New Session")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 28)
                } else if vm.sessionActive {
                    Button {
                        vm.stopSession()
                    } label: {
                        Label("End Session", systemImage: "stop.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.glowCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowCoral.opacity(0.12))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.glowCoral.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 28)
                } else if vm.currentUV >= 1 {
                    Button {
                        vm.startSession()
                    } label: {
                        Label("Start Session", systemImage: "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 28)
                }

                Spacer().frame(height: 120)
            }
        }
    }

    private var timerString: String {
        let m = vm.sessionSecondsRemaining / 60
        let s = vm.sessionSecondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }
}
