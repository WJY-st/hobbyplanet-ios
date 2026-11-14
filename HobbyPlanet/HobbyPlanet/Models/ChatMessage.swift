//
//  ChatMessage.swift
//  HobbyPlanet
//
//  AI 助手会话中的单条消息。只做 UI 展示需要的最小字段，
//  真正发给模型的上下文在 AssistantService 里组装。
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var text: String
    /// 消息来源：真实模型 / 本地降级
    var source: Source
    let createdAt: Date

    enum Source: String, Equatable {
        case model
        case offline

        var badge: String? {
            switch self {
            case .model: return nil
            case .offline: return "离线回答"
            }
        }
    }

    init(id: UUID = UUID(),
         role: Role,
         text: String,
         source: Source = .model,
         createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.source = source
        self.createdAt = createdAt
    }

    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: .user, text: text)
    }

    static func assistant(_ text: String, source: Source = .model) -> ChatMessage {
        ChatMessage(role: .assistant, text: text, source: source)
    }
}
