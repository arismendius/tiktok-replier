import Foundation

enum LLMBackend: String, Codable, CaseIterable {
    case lmStudio = "lmstudio"
    case ollama   = "ollama"
    var label: String { self == .lmStudio ? "LM Studio" : "Ollama" }
    var defaultURL: String { self == .lmStudio ? "http://localhost:1234/v1" : "http://localhost:11434/v1" }
}

struct AppConfig: Codable {
    var backend: LLMBackend = .lmStudio
    var lmStudioURL: String = "http://localhost:1234/v1"
    var modelName: String = "qwen3.6-35b-a3b"
    var apiKey: String = ""
    var batchSize: Int = 10
    var delayBetweenReplies: Double = 8.0
    var promptInstructions: String = "You are a friendly, authentic TikTok creator replying to comments on your videos. Keep replies short (1-2 sentences max), warm, and conversational. Always match the language of the comment exactly. Never use hashtags in replies. Be genuine, never corporate or robotic."
    var autoPost: Bool = true
}

struct TikTokComment: Identifiable, Codable {
    let id: String
    let commentText: String
    let commenterUsername: String
    let commenterNickname: String
    let videoID: String
    let createTime: TimeInterval
    var generatedReply: String?
    var status: ReplyStatus = .pending
    enum ReplyStatus: String, Codable {
        case pending, generating, posted, failed, skipped
    }
}

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let commenter: String
    let comment: String
    let reply: String
    let status: String
    let videoID: String
    init(commenter: String, comment: String, reply: String, status: String, videoID: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.commenter = commenter
        self.comment = comment
        self.reply = reply
        self.status = status
        self.videoID = videoID
    }
}

struct LMStudioRequest: Codable {
    let model: String
    let messages: [LMMessage]
    let maxTokens: Int
    let temperature: Double
    let stream: Bool
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

struct LMMessage: Codable {
    let role: String
    let content: String
}

struct LMStudioResponse: Codable {
    let choices: [LMChoice]
}

struct LMChoice: Codable {
    let message: LMMessage
}

struct TikTokCommentsResponse: Codable {
    let comments: [TikTokAPIComment]?
    let hasMore: Bool?
    let cursor: String?
    enum CodingKeys: String, CodingKey {
        case comments
        case hasMore = "has_more"
        case cursor
    }
}

struct TikTokAPIComment: Codable {
    let cid: String
    let text: String
    let user: TikTokAPIUser
    let replyCommentTotal: Int?
    let awemeID: String?
    enum CodingKeys: String, CodingKey {
        case cid, text, user
        case replyCommentTotal = "reply_comment_total"
        case awemeID = "aweme_id"
    }
}

struct TikTokAPIUser: Codable {
    let uid: String
    let uniqueID: String?
    let nickname: String?
    enum CodingKeys: String, CodingKey {
        case uid
        case uniqueID = "unique_id"
        case nickname
    }
}

struct TikTokVideoListResponse: Codable {
    let awemeList: [TikTokVideo]?
    enum CodingKeys: String, CodingKey {
        case awemeList = "aweme_list"
    }
}

struct TikTokVideo: Codable {
    let awemeID: String
    let desc: String?
    enum CodingKeys: String, CodingKey {
        case awemeID = "aweme_id"
        case desc
    }
}
