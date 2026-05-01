import SwiftUI

struct SettingsView: View {
    @Binding var config: AppConfig
    @State private var lmConnected: Bool? = nil
    @State private var testingConnection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // Backend picker
                SettingsSection(title: "BACKEND") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LLM Provider").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                        Picker("", selection: $config.backend) {
                            ForEach(AppConfig.LLMBackend.allCases, id: \.self) { b in
                                Text(b.rawValue).tag(b)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                // LM Studio settings
                if config.backend == .lmStudio {
                    SettingsSection(title: "LM STUDIO") {
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Endpoint URL")
                            TextField("http://localhost:1234/v1", text: $config.lmStudioURL)
                                .styledField()
                            FieldLabel("Model name")
                            TextField("qwen3.6-35b-a3b", text: $config.lmStudioModel)
                                .styledField()
                            FieldLabel("API Key (optional)")
                            SecureField("Leave empty if not set", text: $config.lmStudioAPIKey)
                                .styledField()
                        }
                    }
                }

                // Ollama settings
                if config.backend == .ollama {
                    SettingsSection(title: "OLLAMA") {
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel("Endpoint URL")
                            TextField("http://localhost:11434", text: $config.ollamaURL)
                                .styledField()
                            FieldLabel("Model name")
                            TextField("qwen3:35b-a3b", text: $config.ollamaModel)
                                .styledField()
                            Text("Model must be pulled in Ollama first")
                                .font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                }

                // Test connection
                SettingsSection(title: "CONNECTION") {
                    HStack {
                        Button(action: testConnection) {
                            HStack(spacing: 6) {
                                if testingConnection {
                                    ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                                }
                                Text(testingConnection ? "Testing..." : "Test Connection")
                            }
                            .font(.system(size: 11)).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color(red: 0.25, green: 0.25, blue: 0.25)).cornerRadius(6)
                        }.buttonStyle(.plain).disabled(testingConnection)

                        if let ok = lmConnected {
                            Label(
                                ok ? "\(config.backend.rawValue) connected" : "Not reachable",
                                systemImage: ok ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .font(.system(size: 11)).foregroundColor(ok ? .green : .red)
                        }
                    }
                }

                // Timing
                SettingsSection(title: "TIMING") {
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel("Delay between replies: \(Int(config.delayBetweenReplies))s")
                        Slider(value: $config.delayBetweenReplies, in: 3...30, step: 1)
                            .tint(Color(red: 1, green: 0.17, blue: 0.33))
                        Text("Keep above 5s to avoid TikTok rate limits")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }

                // Prompt
                SettingsSection(title: "REPLY INSTRUCTIONS") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("System prompt sent to the model. Define tone, style, language rules.")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        TextEditor(text: $config.promptInstructions)
                            .font(.system(size: 12)).frame(height: 120)
                            .padding(6).background(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .cornerRadius(6).scrollContentBackground(.hidden)
                        Button("Reset to default") { config.promptInstructions = AppConfig().promptInstructions }
                            .buttonStyle(.plain).font(.system(size: 11)).foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
        }
    }

    private func testConnection() {
        testingConnection = true; lmConnected = nil
        Task {
            lmConnected = await LMStudioService.shared.testConnection(config: config)
            testingConnection = false
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(red: 1, green: 0.17, blue: 0.33)).kerning(1.5)
            Divider()
            content
        }
        .padding(12).background(Color(red: 0.16, green: 0.16, blue: 0.16)).cornerRadius(8)
    }
}

struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
    }
}

extension View {
    func styledField() -> some View {
        self
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .monospaced))
            .padding(8)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(6)
    }
}
