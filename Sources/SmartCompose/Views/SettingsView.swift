import SwiftUI

/// Application settings for prediction behavior and data management.
struct SettingsView: View {

    @AppStorage("predictionsEnabled") private var predictionsEnabled: Bool = true
    @AppStorage("predictionAggressiveness") private var aggressiveness: Double = 0.5
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    var body: some View {
        NavigationStack {
            List {
                // PREDICTIONS
                Section {
                    Toggle(isOn: $predictionsEnabled) {
                        Label("Enable Predictions", systemImage: "sparkles")
                    }
                    .tint(Theme.accent)

                    if predictionsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Prediction Sensitivity")
                                    .font(.subheadline)
                                Spacer()
                                Text(sensitivityLabel)
                                    .font(Theme.captionFont)
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $aggressiveness, in: 0.1...1.0, step: 0.1)
                                .tint(Theme.accent)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Predictions")
                } footer: {
                    Text("Higher sensitivity shows predictions more frequently, even with lower confidence.")
                }

                // NLP ENGINE
                Section {
                    HStack {
                        Label("Framework", systemImage: "cpu")
                        Spacer()
                        Text("NaturalLanguage")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Processing", systemImage: "bolt.fill")
                        Spacer()
                        Text("On-Device Only")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Thread Safety", systemImage: "arrow.triangle.branch")
                        Spacer()
                        Text("Swift Actor")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Text Engine", systemImage: "doc.richtext")
                        Spacer()
                        Text("TextKit 2")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Engine Info")
                }

                // DATA
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Learned Data", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This clears all learned writing patterns and resets the prediction model to its default state. Your documents are not affected.")
                }

                // ABOUT
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Platform", systemImage: "iphone")
                        Spacer()
                        Text("iOS 17.0+")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Developer", systemImage: "person.fill")
                        Spacer()
                        Text("Bhushan Asati")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset Learned Data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    Task {
                        await LanguageModelStore.shared.resetToDefaults()
                        showResetSuccess = true
                        HapticManager.shared.documentAction()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all learned writing patterns. Your documents will not be deleted.")
            }
            .overlay {
                if showResetSuccess {
                    resetSuccessBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showResetSuccess = false
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Helpers

    private var sensitivityLabel: String {
        switch aggressiveness {
        case ..<0.3: return "Conservative"
        case 0.3..<0.7: return "Balanced"
        default: return "Aggressive"
        }
    }

    private var resetSuccessBanner: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Learned data has been reset")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .padding()

            Spacer()
        }
    }
}
