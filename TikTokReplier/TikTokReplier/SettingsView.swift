import SwiftUI

struct SettingsView: View {
    @Binding var config: AppConfig
    @State private var lmConnected: Bool? = nil
    @State private var testingConnection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsSection(title: "BACKEND") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: $config.backend) {
                            ForEach(LLMBackend.allCases, id: \.self) { b in
                                Text(b.label).tag(b)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: config.backend) { newBackend in
                            config.lmStudioURL = newBackend.defaultURL
                            lmConnected = nil
                        }

                        Text("Endpoint URL").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                        TextField(config.backend.defaultURL, text: $config.lmStudioURL)
                            .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced))
                            .padding(8).background(Color(red: 0.1, green: 0.1, blue: 0.1)).cornerRadius(6)

                        Text("Model name").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                        TextField("model name", text: $config.modelName)
                            .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced))
                            .padding(8).background(Color(red: 0.1, green: 0.1, blue: 0.1)).cornerRadius(6)

                        Text("API key (optional)").font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                        SecureField("Leave blank for local / no auth", text: $config.apiKey)
                            .textFieldStyle(.plain).font(.system(size: 12, design: .monospaced))
                            .padding(8).background(Color(red: 0.1, green: 0.1, blue: 0.1)).cornerRadius(6)

                        HStack {
                            Button(action: testConnection) {
                                HStack(spacing: 6) {
                                    if testingConnection { ProgressView().scaleEffect(0.6).frame(width: 12, height: 12) }
                                    Text(testingConnection ? "Testing..." : "Test Connection")
                                }
                                .font(.system(size: 11)).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color(red: 0.25, green: 0.25, blue: 0.25)).cornerRadius(6)
                            }.buttonStyle(.plain).disabled(testingConnection)
                            if let ok = lmConnected {
                                Label(ok ? "Connected" : "Not reachable",
                                      systemImage: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 11)).foregroundColor(ok ? .green : .red)
                            }
                        }
                    }
                }

                SettingsSection(title: "TIMING") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Delay between replies: \(Int(config.delayBetweenReplies))s")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                        Slider(value: $config.delayBetweenReplies, in: 3...30, step: 1)
                            .tint(Color(red: 1, green: 0.17, blue: 0.33))
                        Text("Keep above 5s to avoid TikTok rate limits")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }

                SettingsSection(title: "REPLY INSTRUCTIONS") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("System prompt. Define your tone, style, language rules.")
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
