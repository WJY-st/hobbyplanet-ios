//
//  AssistantService.swift
//  HobbyPlanet
//
//  AI 助手的会话编排：把用户档案与近期活动压缩成上下文，
//  拼进 system prompt，再带上最近若干轮对话。断网时用规则回答，保证界面永远有反馈。
//

import Foundation

struct AssistantService {
    let client: LLMClient
    let profile: UserProfile
    let activities: [HobbyActivity]

    /// 只保留最近 6 轮，防止上下文无限增长导致 token 超限
    static let historyLimit = 6

    func answer(history: [ChatMessage], question: String) async -> (text: String, fromModel: Bool) {
        let messages = AssistantService.buildMessages(
            profile: profile,
            activities: activities,
            history: history,
            question: question
        )

        do {
            let text = try await client.chat(messages: messages, temperature: 0.6, maxTokens: 700)
            return (text.trimmingCharacters(in: .whitespacesAndNewlines), true)
        } catch {
            let fallback = AssistantService.offlineAnswer(
                question: question,
                activities: activities,
                profile: profile
            )
            return (fallback, false)
        }
    }

    // MARK: - 上下文组装

    static func buildMessages(profile: UserProfile,
                              activities: [HobbyActivity],
                              history: [ChatMessage],
                              question: String) -> [LLMMessage] {
        var messages: [LLMMessage] = [.system(systemPrompt(profile: profile, activities: activities))]

        let recent = history.suffix(historyLimit * 2)
        for message in recent {
            switch message.role {
            case .user:
                messages.append(.user(message.text))
            case .assistant:
                messages.append(.assistant(message.text))
            }
        }
        messages.append(.user(question))
        return messages
    }

    static func systemPrompt(profile: UserProfile, activities: [HobbyActivity]) -> String {
        let interestText = profile.interests.isEmpty
            ? "还没有选择兴趣标签"
            : profile.interests.sorted().joined(separator: "、")

        let ongoing = activities
            .filter { !$0.isFinished }
            .sorted { $0.startAt < $1.startAt }
            .prefix(6)
            .map { "· \($0.title)｜\(Fmt.activityTime($0.startAt))｜\($0.location)｜\($0.seatsOrFullText)" }
            .joined(separator: "\n")

        return """
        你是「同好星球」App 里的校园活动助手，说话简洁、具体、像同学之间的建议。
        规则：
        1. 回答控制在 120 字以内，能用列表就用列表，不要空话。
        2. 只根据下面提供的活动和兴趣回答，不要编造不存在的活动和地点。
        3. 如果用户问“推荐什么”，优先从近期活动里挑 1 到 2 个，并说明为什么适合他。
        4. 不确定时直接说“我不太确定”，并建议用户在「发现」页看看。

        用户昵称：\(profile.displayName)
        用户兴趣标签：\(interestText)

        近期活动：
        \(ongoing.isEmpty ? "暂无" : ongoing)
        """
    }

    // MARK: - 离线兜底

    static func offlineAnswer(question: String, activities: [HobbyActivity], profile: UserProfile) -> String {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let ranked = MatchEngine.ranked(activities.filter { !$0.isFinished }, profile: profile)

        if text.contains("推荐") || text.contains("有什么") || text.contains("去哪") {
            guard let best = ranked.first else {
                return "现在还没有进行中的活动，去「发现」页发起一个试试？"
            }
            let more = ranked.dropFirst().prefix(2)
                .map { "· \($0.activity.title)（\($0.activity.timeText)）" }
                .joined(separator: "\n")
            return """
            最近最适合你的是「\(best.activity.title)」：
            \(best.activity.timeText) · \(best.activity.location)
            推荐理由：\(best.reasons.joined(separator: "，"))。
            \(more.isEmpty ? "" : "\n还有这些：\n\(more)")
            """
        }

        if text.contains("周末") {
            let weekend = ranked.filter { Calendar.current.isDateInWeekend($0.activity.startAt) }.prefix(3)
            if weekend.isEmpty {
                return "这个周末暂时没有排期，可以自己在「发布」页发起一个。"
            }
            let lines = weekend.map { "· \($0.activity.title)（\($0.activity.timeText)）" }.joined(separator: "\n")
            return "周末可以看看这几场：\n\(lines)"
        }

        if text.contains("怎么发") || text.contains("发起") || text.contains("发布") {
            return """
            点底部「发布」，先去「AI 策划」用一句话描述想法，
            它会生成标题、简介、步骤和物料，确认后直接发布。
            """
        }

        return """
        现在没有连上大模型，我只能给你本地建议：
        你的兴趣是 \(profile.interests.isEmpty ? "还没选择" : profile.interests.sorted().prefix(3).joined(separator: "、"))，
        「发现」页里匹配度最高的是「\(ranked.first?.activity.title ?? "暂无活动")」。
        配置密钥后可以问我更灵活的问题。
        """
    }
}

private extension HobbyActivity {
    /// system prompt 里用的简短余位文案
    var seatsOrFullText: String {
        isFull ? "已满员" : "还剩 \(remainingSeats) 个位置"
    }
}
