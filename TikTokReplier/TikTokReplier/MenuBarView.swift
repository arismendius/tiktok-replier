import SwiftUI

struct MenuBarView: View {
    @ObservedObject var state: AppStateManager
    @State private var selectedTab = 0
    @State private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("🎵 TikTok Replier")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(state.engine.isRunning ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(state.engine.isRunning ? "Running" : "Ready")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(red: 0.08, green: 0.08, blue: 0.08))

            HStack(spacing: 0) {
                ForEach(["▶ Run", "⚙ Settings", "📋 Log", "🔑 Login"].indices, id: \.self) { i in
                    let labels = ["▶ Run", "⚙ Settings", "📋 Log", "🔑 Login"]
                    Button(action: { selectedTab = i }) {
                        Text(labels[i])
                            .font(.system(size: 11, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? .white : .secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(selectedTab == i ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.clear)
                }
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))

            Divider()

            Group {
                switch selectedTab {
                case 0: RunView(state: state, isLoggedIn: isLoggedIn)
                case 1: SettingsView(config: $state.config)
                case 2: LogView()
                case 3: LoginTab(isLoggedIn: $isLoggedIn)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            HStack {
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundColor(.secondary)
                    .padding(.horizontal, 16).padding(.vertical, 8)
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .onAppear { Task { isLoggedIn = await TikTokService.shared.isLoggedIn() } }
    }
}

struct RunView: View {
    @ObservedObject var state: AppStateManager
    let isLoggedIn: Bool

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Status").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                    Spacer()
                    if state.engine.isRunning { ProgressView().scaleEffect(0.6).frame(width: 16, height: 16) }
                }
                Text(state.engine.currentStatus.isEmpty ? "Idle" : state.engine.currentStatus)
                    .font(.system(size: 12)).foregroundColor(.white).lineLimit(2)
                if state.engine.progress.total > 0 {
                    ProgressView(value: Double(state.engine.progress.done), total: Double(state.engine.progress.total))
                        .tint(Color(red: 1, green: 0.17, blue: 0.33)).padding(.top, 2)
                    Text("\(state.engine.progress.done) / \(state.engine.progress.total)")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
            }
            .padding(12).background(Color(red: 0.16, green: 0.16, blue: 0.16)).cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text("Batch size").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach([5, 10, 20, 50], id: \.self) { n in
                        Button(action: { state.config.batchSize = n }) {
                            Text("\(n)")
                                .font(.system(size: 12, weight: state.config.batchSize == n ? .bold : .regular))
                                .foregroundColor(state.config.batchSize == n ? .white : .secondary)
                                .frame(width: 40, height: 28)
                                .background(state.config.batchSize == n ? Color(red: 1, green: 0.17, blue: 0.33) : Color(red: 0.2, green: 0.2, blue: 0.2))
                                .cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(12).background(Color(red: 0.16, green: 0.16, blue: 0.16)).cornerRadius(8)

            Spacer()

            if !isLoggedIn {
                Label("Not logged in - use Login tab", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11)).foregroundColor(.orange)
            }

            HStack(spacing: 10) {
                Button(action: { state.engine.run(config: state.config) }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Run Now")
                    }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(state.engine.isRunning || !isLoggedIn ? Color.gray : Color(red: 1, green: 0.17, blue: 0.33))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain).disabled(state.engine.isRunning || !isLoggedIn)

                if state.engine.isRunning {
                    Button(action: { state.engine.stop() }) {
                        HStack { Image(systemName: "stop.fill"); Text("Stop") }
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            .frame(width: 80).padding(.vertical, 10)
                            .background(Color(red: 0.3, green: 0.3, blue: 0.3)).cornerRadius(8)
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }
}

struct LoginTab: View {
    @Binding var isLoggedIn: Bool
    var body: some View {
        VStack(spacing: 0) {
            if isLoggedIn {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundColor(.green)
                    Text("Logged in to TikTok").font(.system(size: 14, weight: .semibold))
                    Text("Session saved. No need to log in again.")
                        .font(.system(size: 11)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button("Log out") {
                        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { isLoggedIn = false }
                    }
                    .buttonStyle(.plain).foregroundColor(.red).padding(.top, 8)
                }
                .padding(24)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "info.circle").foregroundColor(.secondary)
                        Text("Log in below - session saves automatically")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                    }.padding(10)
                    LoginWebView(isLoggedIn: $isLoggedIn)
                }
            }
        }
    }
}
