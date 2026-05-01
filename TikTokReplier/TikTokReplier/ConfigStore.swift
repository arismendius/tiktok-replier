import Foundation
import Combine

class ConfigStore: ObservableObject {
    static let shared = ConfigStore()
    @Published var config: AppConfig { didSet { save() } }
    @Published var log: [LogEntry] = []
    private let configURL: URL
    private let logURL: URL
    private let repliedIDsURL: URL
    private(set) var repliedCommentIDs: Set<String> = []

    private init() {
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".tiktok_replier")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        configURL = dir.appendingPathComponent("config.json")
        logURL = dir.appendingPathComponent("log.json")
        repliedIDsURL = dir.appendingPathComponent("replied_ids.json")
        config = Self.load(from: dir.appendingPathComponent("config.json")) ?? AppConfig()
        log = Self.load(from: dir.appendingPathComponent("log.json")) ?? []
        repliedCommentIDs = Self.load(from: dir.appendingPathComponent("replied_ids.json")) ?? []
    }

    private static func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(config) { try? data.write(to: configURL) }
    }

    func appendLog(_ entry: LogEntry) {
        DispatchQueue.main.async {
            self.log.insert(entry, at: 0)
            if self.log.count > 500 { self.log = Array(self.log.prefix(500)) }
            if let data = try? JSONEncoder().encode(self.log) { try? data.write(to: self.logURL) }
        }
    }

    func markReplied(commentID: String) {
        repliedCommentIDs.insert(commentID)
        if let data = try? JSONEncoder().encode(repliedCommentIDs) { try? data.write(to: repliedIDsURL) }
    }

    func hasReplied(to commentID: String) -> Bool { repliedCommentIDs.contains(commentID) }
}
