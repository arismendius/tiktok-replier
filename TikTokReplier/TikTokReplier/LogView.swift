import SwiftUI

struct LogView: View {
    @ObservedObject private var store = ConfigStore.shared
    var body: some View {
        VStack(spacing: 0) {
            if store.log.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble").font(.system(size: 32)).foregroundColor(.secondary)
                    Text("No replies logged yet").foregroundColor(.secondary).font(.system(size: 12))
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    let posted = store.log.filter { $0.status == "posted" }.count
                    let failed = store.log.filter { $0.status != "posted" }.count
                    Label("\(posted) posted", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                    Spacer()
                    Label("\(failed) failed", systemImage: "xmark.circle.fill").foregroundColor(.red)
                    Spacer()
                    Button("Clear") { ConfigStore.shared.log = [] }
                        .buttonStyle(.plain).font(.system(size: 11)).foregroundColor(.secondary)
                }
                .font(.system(size: 11)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(red: 0.14, green: 0.14, blue: 0.14))
                Divider()
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(store.log) { LogEntryRow(entry: $0) }
                    }
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    @State private var expanded = false
    var statusColor: Color { entry.status == "posted" ? .green : .red }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }) {
                HStack(spacing: 8) {
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("@\(entry.commenter)").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                            Spacer()
                            Text(entry.timestamp, style: .relative).font(.system(size: 10)).foregroundColor(.secondary)
                        }
                        Text(entry.comment).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            }.buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().padding(.horizontal, 12)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COMMENT").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary).kerning(1)
                        Text(entry.comment).font(.system(size: 11)).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                    }.padding(.horizontal, 20)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REPLY").font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 1, green: 0.17, blue: 0.33)).kerning(1)
                        Text(entry.reply).font(.system(size: 11)).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                    }.padding(.horizontal, 20).padding(.bottom, 10)
                }.background(Color(red: 0.14, green: 0.14, blue: 0.14))
            }
        }
        .background(Color(red: expanded ? 0.14 : 0.12, green: expanded ? 0.14 : 0.12, blue: expanded ? 0.14 : 0.12))
    }
}
