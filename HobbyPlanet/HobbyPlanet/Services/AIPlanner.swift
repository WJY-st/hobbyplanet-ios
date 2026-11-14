//
//  AIPlanner.swift
//  HobbyPlanet
//
//  “AI 策划官”的工程实现：用受约束的提示词让模型输出一段 JSON，
//  再把 JSON 校验、裁剪成可以直接回填表单的 AIPlanDraft。
//  解析失败不抛出到界面，而是交给 FallbackPlanner 用本地模板兜底。
//

import Foundation

struct AIPlanner {
    let client: LLMClient

    static let systemPrompt = """
    你是「同好星球」的校园兴趣活动策划助手，服务对象是大学生。
    用户会给你一句很随意的话，你要把它整理成一份可以直接发布的活动方案。

    硬性要求：
    1. 只输出一个 JSON 对象，不要 Markdown 代码块，不要任何解释文字。
    2. JSON 字段固定为：title, summary, steps, materials, tags, duration_minutes, capacity。
    3. title 不超过 20 个汉字，口语化、具体，不要写“活动方案”之类的大词。
    4. summary 不超过 100 个汉字，说清楚“做什么、怎么做、适合谁”。
    5. steps 是 3 到 6 条执行步骤，每条不超过 18 个汉字。
    6. materials 是需要自带或 AA 的物品，0 到 6 条；没有就返回空数组。
    7. tags 是 2 到 4 个兴趣标签，只能从这些词里选：陶艺、烘焙、编织、拼豆、印章、手账、皮具、花艺、猫咖、遛狗、宠物摄影、领养、异宠、宠物友好店、救助站、训犬、咖啡、面包、烧烤、川菜、甜品、夜宵、食堂测评、小众餐厅、话剧社、摄影社、志愿活动、读书会、桌游、辩论、支教、社团招新、夜跑、羽毛球、篮球、飞盘、游泳、骑行、爬山、健身、吉他、合唱、livehouse、街唱、作曲、乐队、黑胶、音乐节。
    8. duration_minutes 是 30 到 240 的整数，capacity 是 4 到 50 的整数。
    9. 不要编造具体店名以外的敏感信息，不要写价格承诺。

    示例输出：
    {"title":"周五夜跑五公里","summary":"操场刷圈，配速随意，跑完一起吃夜宵。适合想动一动又怕坚持不下来的人。","steps":["东看台集合热身","分组开跑五公里","拉伸并合影"],"materials":["运动鞋","水"],"tags":["夜跑","健身"],"duration_minutes":90,"capacity":16}
    """

    // MARK: - 主流程

    /// 返回草案与来源标记（true 表示来自模型，false 表示本地降级）
    func generate(prompt: String, category: HobbyCategory, profile: UserProfile) async -> (draft: AIPlanDraft, fromModel: Bool, note: String?) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (FallbackPlanner.draft(prompt: category.title, category: category), false, "先写一句你的想法吧")
        }

        let interestText = profile.interests.isEmpty ? "暂未选择" : profile.interests.sorted().joined(separator: "、")
        let userContent = """
        活动分类：\(category.title)
        我的兴趣标签：\(interestText)
        我的想法：\(trimmed)
        请输出 JSON。
        """

        do {
            let raw = try await client.chat(
                messages: [.system(AIPlanner.systemPrompt), .user(userContent)],
                temperature: 0.8,
                maxTokens: 700
            )
            let draft = try AIPlanner.parse(raw)
            return (draft, true, nil)
        } catch let error as LLMError {
            let fallback = FallbackPlanner.draft(prompt: trimmed, category: category)
            let note: String
            switch error {
            case .missingKey:
                note = "未配置密钥，已用本地模板生成草案"
            case .decoding:
                note = "模型输出不是合法 JSON，已切换到本地模板"
            default:
                note = "调用失败（\(error.errorDescription ?? "未知")），已切换到本地模板"
            }
            return (fallback, false, note)
        } catch {
            return (FallbackPlanner.draft(prompt: trimmed, category: category), false, "调用失败，已切换到本地模板")
        }
    }

    // MARK: - 解析与校验

    /// 从模型返回的文本里提取 JSON 并校验。容忍 ```json 包裹、前后废话、字段名写法差异。
    static func parse(_ raw: String) throws -> AIPlanDraft {
        let text = stripCodeFence(raw)

        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else {
            throw LLMError.decoding
        }

        let jsonText = String(text[start...end])
        guard let data = jsonText.data(using: .utf8) else {
            throw LLMError.decoding
        }

        // 第一优先：严格按 Codable 解码
        if let strict = try? JSONDecoder().decode(AIPlanDraft.self, from: data) {
            return sanitize(strict)
        }

        // 第二优先：用 JSONSerialization 做宽松解析，兼容 durationMinutes / 数字以字符串给出等写法
        guard let any = try? JSONSerialization.jsonObject(with: data),
              let object = any as? [String: Any] else {
            throw LLMError.decoding
        }

        return sanitize(looseDraft(from: object))
    }

    static func stripCodeFence(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            // 去掉第一行的 ``` 或 ```json
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looseDraft(from object: [String: Any]) -> AIPlanDraft {
        func string(_ keys: [String]) -> String {
            for key in keys {
                if let value = object[key] as? String { return value }
                if let number = object[key] as? NSNumber { return number.stringValue }
            }
            return ""
        }

        func strings(_ keys: [String]) -> [String] {
            for key in keys {
                if let value = object[key] as? [String] { return value }
                if let value = object[key] as? String {
                    return value
                        .components(separatedBy: CharacterSet(charactersIn: "\n、,，;；"))
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                }
            }
            return []
        }

        func int(_ keys: [String], fallback: Int) -> Int {
            for key in keys {
                if let value = object[key] as? Int { return value }
                if let value = object[key] as? Double { return Int(value) }
                if let text = object[key] as? String, let value = Int(text) { return value }
            }
            return fallback
        }

        return AIPlanDraft(
            title: string(["title", "name"]),
            summary: string(["summary", "desc", "description"]),
            steps: strings(["steps", "plan", "流程"]),
            materials: strings(["materials", "items", "物料"]),
            tags: strings(["tags", "labels"]),
            durationMinutes: int(["duration_minutes", "durationMinutes", "duration"], fallback: 120),
            capacity: int(["capacity", "seats", "人数"], fallback: 12)
        )
    }

    /// 把模型给的任意内容裁剪到界面能安全展示的范围
    static func sanitize(_ draft: AIPlanDraft) -> AIPlanDraft {
        var result = draft

        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        result.title = title.isEmpty ? "临时起意的兴趣小活动" : String(title.prefix(20))

        let summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        result.summary = summary.isEmpty ? "一起做点有意思的事，来了就能加入。" : String(summary.prefix(100))

        result.steps = Array(
            draft.steps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(6)
        )
        if result.steps.isEmpty {
            result.steps = ["集合签到", "开始活动", "合影留念"]
        }

        result.materials = Array(
            draft.materials
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(6)
        )

        result.tags = HobbyLibrary.normalize(draft.tags, limit: 4)
        if result.tags.isEmpty {
            result.tags = ["同好"]
        }

        result.durationMinutes = min(240, max(30, draft.durationMinutes))
        result.capacity = min(50, max(4, draft.capacity))
        return result
    }
}
