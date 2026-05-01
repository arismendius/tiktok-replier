import Foundation

actor LMStudioService {
    static let shared = LMStudioService()

    func testConnection(url: String) async -> Bool {
        guard let endpoint = URL(string: "\(url)/models") else { return false }
        var req = URLRequest(url: endpoint, timeoutInterval: 5)
        req.httpMethod = "GET"
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    func generateReply(for comment: String, config: AppConfig) async throws -> String {
        guard let endpoint = URL(string: "\(config.lmStudioURL)/chat/completions") else { throw LMError.invalidURL }
        let body = LMStudioRequest(
            model: config.modelName,
            messages: [
                LMMessage(role: "system", content: config.promptInstructions),
                LMMessage(role: "user", content: "Reply to this TikTok comment: \"\(comment)\""),
            ],
            maxTokens: 120, temperature: 0.85, stream: false
        )
        var req = URLRequest(url: endpoint, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw LMError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(LMStudioResponse.self, from: data)
        var reply = decoded.choices.first?.message.content ?? ""
        reply = reply.replacingOccurrences(of: #"<think>[\s\S]*?</think>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return reply
    }

    enum LMError: LocalizedError {
        case invalidURL, httpError(Int)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid LM Studio URL"
            case .httpError(let c): return "LM Studio HTTP \(c)"
            }
        }
    }
}
