import SwiftUI
import RevenueCat

struct SettingsView: View {
    @ObservedObject var vm: HomeViewModel
    @EnvironmentObject private var premium: PremiumState
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var showSkinTypePicker = false
    @State private var isRestoring = false
    @State private var isManagingSubscription = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    HStack {
                        Text(premium.isPremium ? "TanCast Premium" : "Free Plan")
                            .font(.headline)
                        Spacer()
                        if premium.isPremium {
                            Label("Active", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    if premium.isPremium {
                        Button {
                            isManagingSubscription = true
                            Task {
                                try? await Purchases.shared.showManageSubscriptions()
                                isManagingSubscription = false
                            }
                        } label: {
                            if isManagingSubscription {
                                ProgressView()
                            } else {
                                Text("Manage Subscription")
                            }
                        }
                        .disabled(isManagingSubscription)
                    } else {
                        Button("Upgrade to Premium") { showPaywall = true }
                    }

                    Button {
                        isRestoring = true
                        restoreMessage = nil
                        Task {
                            do {
                                _ = try await PremiumState.shared.restore()
                                restoreMessage = premium.isPremium ? "Restored!" : "No previous purchase found."
                            } catch {
                                restoreMessage = "Restore failed. Please try again."
                            }
                            isRestoring = false
                        }
                    } label: {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Text("Restore Purchases")
                        }
                    }
                    .disabled(isRestoring)

                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Your Profile") {
                    Button {
                        showSkinTypePicker = true
                    } label: {
                        HStack {
                            Circle()
                                .fill(vm.skinType.skinColor)
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.skinType.displayName)
                                    .foregroundColor(.primary)
                                Text(vm.skinType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Picker("Tan Goal", selection: Binding(
                        get: { vm.tanGoal },
                        set: { vm.updateTanGoal($0) }
                    )) {
                        ForEach(TanGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }

                    Toggle("Sun allergy / photosensitivity", isOn: Binding(
                        get: { vm.hasPhotosensitivity },
                        set: { vm.updateHasPhotosensitivity($0) }
                    ))
                }

                Section {
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("Privacy Policy", destination: URL(string: "https://destiny-fender-4ad.notion.site/Privacy-Policy-TanCast-App-UV-Protection-3a477834762b80199fecefbafe4cbeef")!)
                }

                #if DEBUG
                Section("Debug") {
                    Button(premium.isPremium ? "Disable Premium (Debug)" : "Enable Premium (Debug)") {
                        premium.debugSetPremium(!premium.isPremium)
                    }
                    .foregroundColor(.orange)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onSubscribe: { showPaywall = false },
                onRestore: { showPaywall = false },
                onDismiss: { showPaywall = false }
            )
        }
        .sheet(isPresented: $showSkinTypePicker) {
            SkinTypePickerSheet(skinType: Binding(
                get: { vm.skinType },
                set: { vm.updateSkinType($0) }
            ))
        }
    }
}
