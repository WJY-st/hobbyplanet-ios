//
//  LLMDTO.swift
//  HobbyPlanet
//
//  与 OpenAI 兼容接口（DeepSeek / 通义 / 本地网关）交互的数据结构。
//  请求体与响应体严格按 chat/completions 协议建模，任何字段变化只影响这一层。
//

import Foundation

// MARK: - 通用消息

struct LLMMessage: Codable, Equatable {
    let role: String
    let content: String

    init(role: String, content: String) {
        self.role = role
        self.content = content
    }

    static func system(_ content: String) -> LLMMessage {
        LLMMessage(role: "system", content: content)
    }

    static func user(_ content: String) -> LLMMessage {
        LLMMessage(role: "user", content: content)
    }

    static func assistant(_ content: String) -> LLMMessage {
        LLMMessage(role: "assistant", content: content)
    }
}

// MARK: - 请求

struct ChatRequest: Codable {
    let model: String
    let messages: [LLMMessage]
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }

    init(model: String,
         messages: [LLMMessage],
         temperature: Double = 0.7,
         maxTokens: Int = 800,
         stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stream = stream
    }
}

// MARK: - 响应

struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String?
            let content: String?
        }

        let index: Int?
        let message: Message?
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    let id: String?
    let model: String?
    let choices: [Choice]
    let usage: Usage?

    var firstText: String? {
        choices.first?.message?.content?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// 服务端错误响应体：`{"error": {"message": "...", "type": "invalid_request_error"}}`
struct APIErrorBody: Codable {
    struct Payload: Codable {
        let message: String?
        let type: String?
        let code: String?
    }

    let error: Payload?
}

// MARK: - AI 生成的活动草案

/// 大模型返回的结构化活动方案。字段与发布表单一一对应，
/// 因此“生成 → 解析 → 回填”不需要任何中间转换。
struct AIPlanDraft: Codable, Equatable {
    var title: String
    var summary: String
    var steps: [String]
    var materials: [String]
    var tags: [String]
    var durationMinutes: Int
    var capacity: Int

    enum CodingKeys: String, CodingKey {
        case title, summary, steps, materials, tags
        case durationMinutes = "duration_minutes"
        case capacity
    }

    init(title: String,
         summary: String,
         steps: [String],
         materials: [String],
         tags: [String],
         durationMinutes: Int,
         capacity: Int) {
        self.title = title
        self.summary = summary
        self.steps = steps
        self.materials = materials
        self.tags = tags
        self.durationMinutes = durationMinutes
        self.capacity = capacity
    }
}

// MARK: - 错误

enum LLMError: LocalizedError, Equatable {
    case missingKey
    case badURL
    case network(String)
    case rateLimited
    case server(Int, String)
    case emptyResponse
    case decoding
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "还没有配置大模型密钥，请到「我的 → 设置」里填写。"
        case .badURL:
            return "接口地址格式不正确，请检查设置里的 Base URL。"
        case .network(let detail):
            return "网络请求失败：\(detail)"
        case .rateLimited:
            return "请求太频繁了，等一会儿再试。"
        case .server(let code, let message):
            return "服务端返回 \(code)：\(message)"
        case .emptyResponse:
            return "模型没有返回内容，换个说法再试试。"
        case .decoding:
            return "返回内容无法解析，已切换到本地模板。"
        case .cancelled:
            return "请求已取消。"
        }
    }
}
