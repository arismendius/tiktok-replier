import Foundation

actor LMStudioService {
    static let shared = LMStudioService()

    func testConnection(config: AppConfig) async -> Bool {
        let urlStr = config.backend == .lmStudio
            ? "\(config.lmStudioURL)/models"
            : "\(config.ollamaURL)/api/tags"
        guard let url = URL(string: urlStr) else { return false }
        var req = URLRequest(url: url, timeoutInterval: 5)
        req.httpMethod = "GET"
        if config.backend == .lmStudio, !config.lmStudioAPIKey.isEmpty {
            req.setValue("Bearer \(config.lmStudioAPIKey)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    func generateReply(for comment: String, config: AppConfig) async throws -> String {
        switch config.backend {
        case .lmStudio:
            return try await callLMStudio(comment: comment, config: config)
        case .ollama:
            return try await callOllama(comment: comment, config: config)
        }
    }

    private func callLMStudio(comment: String, config: AppConfig) async throws -> String {
        guard let url = URL(string: "\(config.lmStudioURL)/chat/completions") else {
            throw LMError.invalidURL
        }
        let body = LMStudioRequest(
            model: config.lmStudioModel,
            messages: [
                LMMessage(role: "system", content: config.promptInstructions),
                LMMessage(role: "user", content: "Reply to this TikTok comment: \"\(comment)\""),
            ],
            maxTokens: 120, temperature: 0.85, stream: false
        )
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.lmStudioAPIKey.isEmpty {
            req.setValue("Bearer \(config.lmStudioAPIKey)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw LMError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(LMStudioResponse.self, from: data)
        return stripThinking(decoded.choices.first?.message.content ?? "")
    }

    private func callOllama(comment: String, config: AppConfig) async throws -> String {
        guard let url = URL(string: "\(config.ollamaURL)/api/chat") else {
            throw LMError.invalidURL
        }
        let body = OllamaRequest(
            model: config.ollamaModel,
            messages: [
                LMMessage(role: "system", content: config.promptInstructions),
                LMMessage(role: "user", content: "Reply to this TikTok comment: \"\(comment)\""),
            ],
            stream: false,
            options: OllamaOptions(temperature: 0.85, numPredict: 120)
        )
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw LMError.httpError((resp as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return stripThinking(decoded.message.content)
    }

    private func stripThinking(_ text: String) -> String {
        text.replacingOccurrences(of: #"<think>[\s\S]*?</think>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum LMError: LocalizedError {
        case invalidURL, httpError(Int)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .httpError(let c): return "HTTP error \(c)"
            }
        }
    }
}
