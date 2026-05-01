import Foundation
import WebKit

actor TikTokService {
    static let shared = TikTokService()
    private let dataStore = WKWebsiteDataStore.default()

    func isLoggedIn() async -> Bool {
        let cookies = await dataStore.httpCookieStore.allCookies()
        return cookies.contains { $0.domain.contains("tiktok.com") && $0.name == "sessionid" }
    }

    func fetchMyVideos(maxCount: Int = 20) async throws -> [TikTokVideo] {
        let url = URL(string: "https://www.tiktok.com/api/post/item_list/?count=\(maxCount)&cursor=0")!
        let data = try await apiGET(url: url)
        let resp = try JSONDecoder().decode(TikTokVideoListResponse.self, from: data)
        return resp.awemeList ?? []
    }

    func fetchUnansweredComments(videoID: String, maxCount: Int) async throws -> [TikTokComment] {
        var cursor = "0"
        var collected: [TikTokComment] = []
        while collected.count < maxCount {
            let urlStr = "https://www.tiktok.com/api/comment/list/?aweme_id=\(videoID)&count=20&cursor=\(cursor)"
            guard let url = URL(string: urlStr) else { break }
            let data = try await apiGET(url: url)
            let resp = try JSONDecoder().decode(TikTokCommentsResponse.self, from: data)
            guard let comments = resp.comments, !comments.isEmpty else { break }
            for c in comments {
                guard !ConfigStore.shared.hasReplied(to: c.cid) else { continue }
                collected.append(TikTokComment(
                    id: c.cid, commentText: c.text,
                    commenterUsername: c.user.uniqueID ?? c.user.uid,
                    commenterNickname: c.user.nickname ?? c.user.uid,
                    videoID: videoID, createTime: Date().timeIntervalSince1970
                ))
                if collected.count >= maxCount { break }
            }
            guard resp.hasMore == true, let next = resp.cursor, next != cursor else { break }
            cursor = next
        }
        return collected
    }

    func postReply(commentID: String, videoID: String, text: String) async throws {
        let url = URL(string: "https://www.tiktok.com/api/comment/publish/")!
        let params: [String: Any] = ["aweme_id": videoID, "text": text, "reply_id": commentID]
        try await apiPOST(url: url, params: params)
    }

    private func sessionCookies() async -> [HTTPCookie] {
        await dataStore.httpCookieStore.allCookies().filter { $0.domain.contains("tiktok.com") }
    }

    private func apiGET(url: URL) async throws -> Data {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "GET"
        req.setValue("https://www.tiktok.com", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        let cookies = await sessionCookies()
        for (k, v) in HTTPCookie.requestHeaderFields(with: cookies) { req.setValue(v, forHTTPHeaderField: k) }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw TikTokError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    private func apiPOST(url: URL, params: [String: Any]) async throws {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("https://www.tiktok.com", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        let cookies = await sessionCookies()
        for (k, v) in HTTPCookie.requestHeaderFields(with: cookies) { req.setValue(v, forHTTPHeaderField: k) }
        let body = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        req.httpBody = body.data(using: .utf8)
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw TikTokError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    enum TikTokError: LocalizedError {
        case notLoggedIn, httpError(Int)
        var errorDescription: String? {
            switch self {
            case .notLoggedIn: return "Not logged into TikTok"
            case .httpError(let c): return "TikTok API error \(c)"
            }
        }
    }
}
