import Foundation

@MainActor
class ReplyEngine: ObservableObject {
    @Published var isRunning = false
    @Published var currentStatus = ""
    @Published var progress: (done: Int, total: Int) = (0, 0)
    private var task: Task<Void, Never>?

    func run(config: AppConfig) {
        guard !isRunning else { return }
        isRunning = true
        currentStatus = "Starting..."
        progress = (0, 0)
        task = Task { await execute(config: config); isRunning = false; currentStatus = "" }
    }

    func stop() { task?.cancel(); task = nil; isRunning = false; currentStatus = "Stopped" }

    private func execute(config: AppConfig) async {
        let store = ConfigStore.shared
        setStatus("Checking LM Studio...")
        guard await LMStudioService.shared.testConnection(url: config.lmStudioURL) else {
            setStatus("LM Studio not reachable"); return
        }
        setStatus("Checking TikTok session...")
        guard await TikTokService.shared.isLoggedIn() else {
            setStatus("Not logged in - use Login tab"); return
        }
        setStatus("Fetching your videos...")
        let videos: [TikTokVideo]
        do { videos = try await TikTokService.shared.fetchMyVideos(maxCount: 10) }
        catch { setStatus("Failed: \(error.localizedDescription)"); return }
        guard !videos.isEmpty else { setStatus("No videos found"); return }

        setStatus("Scanning comments...")
        var allComments: [TikTokComment] = []
        for video in videos {
            if Task.isCancelled { return }
            if let comments = try? await TikTokService.shared.fetchUnansweredComments(videoID: video.awemeID, maxCount: config.batchSize) {
                allComments.append(contentsOf: comments)
                if allComments.count >= config.batchSize { break }
            }
        }

        let batch = Array(allComments.prefix(config.batchSize))
        guard !batch.isEmpty else { setStatus("No unanswered comments found"); return }
        progress = (0, batch.count)

        for (i, comment) in batch.enumerated() {
            if Task.isCancelled { return }
            setStatus("[\(i+1)/\(batch.count)] Generating reply...")
            do {
                let reply = try await LMStudioService.shared.generateReply(for: comment.commentText, config: config)
                setStatus("[\(i+1)/\(batch.count)] Posting to @\(comment.commenterUsername)...")
                do {
                    try await TikTokService.shared.postReply(commentID: comment.id, videoID: comment.videoID, text: reply)
                    store.markReplied(commentID: comment.id)
                    store.appendLog(LogEntry(commenter: comment.commenterUsername, comment: comment.commentText, reply: reply, status: "posted", videoID: comment.videoID))
                } catch {
                    store.appendLog(LogEntry(commenter: comment.commenterUsername, comment: comment.commentText, reply: reply, status: "post_failed", videoID: comment.videoID))
                }
            } catch {
                store.appendLog(LogEntry(commenter: comment.commenterUsername, comment: comment.commentText, reply: "LM error", status: "lm_error", videoID: comment.videoID))
            }
            progress = (i + 1, batch.count)
            if i < batch.count - 1, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(config.delayBetweenReplies * 1_000_000_000))
            }
        }
        setStatus("Done \(progress.done)/\(progress.total) posted")
    }

    private func setStatus(_ s: String) { currentStatus = s }
}
