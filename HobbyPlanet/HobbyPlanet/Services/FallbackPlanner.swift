//
//  FallbackPlanner.swift
//  HobbyPlanet
//
//  本地降级策划器。没有网络、没有密钥、模型返回不可解析时，
//  用“分类模板 + 用户原话里的关键词”拼出一份结构完整、能直接发布的草案。
//  目标是“能用”，不是“像 AI”。
//

import Foundation

enum FallbackPlanner {
    struct Template {
        let title: String
        let summary: String
        let steps: [String]
        let materials: [String]
        let tags: [String]
        let duration: Int
        let capacity: Int
    }

    static func template(for category: HobbyCategory) -> Template {
        switch category {
        case .handcraft:
            return Template(
                title: "手作小聚：两小时做一件东西",
                summary: "准备好材料就能开始，做完直接带走。零基础也能跟上，互相帮忙剪剪贴贴就好。",
                steps: ["分发材料", "讲解做法", "动手制作", "互相点评", "合影"],
                materials: ["材料包", "湿巾", "围裙"],
                tags: ["手作", "拼豆"],
                duration: 120,
                capacity: 10
            )
        case .pet:
            return Template(
                title: "撸猫遛狗小分队",
                summary: "一起去有猫有狗的地方待一下午，聊聊天、拍拍照，顺手喂个罐头。",
                steps: ["集合签到", "和猫狗熟悉", "拍照记录", "一起收拾"],
                materials: ["湿巾", "充电宝"],
                tags: ["猫咖", "宠物摄影"],
                duration: 90,
                capacity: 8
            )
        case .food:
            return Template(
                title: "校园周边探店小分队",
                summary: "挑三家人少的小店依次打卡，每样分着吃，最后投票选一家最喜欢的。",
                steps: ["集合出发", "按路线探店", "记录评分", "投票总结"],
                materials: ["零钱", "充电宝"],
                tags: ["探店", "咖啡"],
                duration: 150,
                capacity: 12
            )
        case .club:
            return Template(
                title: "同好见面会：先聊起来",
                summary: "找个空教室，围着桌子聊自己最近在做什么，认识几个能说上话的人。",
                steps: ["签到入场", "轮流自我介绍", "主题分享", "自由交流"],
                materials: ["笔记本", "水"],
                tags: ["读书会", "社团招新"],
                duration: 120,
                capacity: 20
            )
        case .sport:
            return Template(
                title: "一起动一动：操场见",
                summary: "不求成绩，只求一起出门。有人带热身，跑不动就走两圈，结束后拉伸。",
                steps: ["集合热身", "分组开始", "拉伸放松", "合影"],
                materials: ["运动鞋", "水"],
                tags: ["夜跑", "健身"],
                duration: 90,
                capacity: 16
            )
        case .music:
            return Template(
                title: "带把琴来唱歌",
                summary: "会三个和弦就能加入，不会就坐着听。想唱什么现场点，气氛随性。",
                steps: ["调音试音", "轮流弹唱", "合唱收尾"],
                materials: ["吉他", "拨片"],
                tags: ["吉他", "街唱"],
                duration: 100,
                capacity: 15
            )
        }
    }

    static func draft(prompt: String, category: HobbyCategory) -> AIPlanDraft {
        let base = template(for: category)
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        // 原话不超过 20 字时直接拿来当标题，超出则用模板标题
        let title: String
        if trimmed.count >= 4 && trimmed.count <= 20 {
            title = trimmed
        } else if trimmed.count > 20 {
            title = String(trimmed.prefix(18)) + "…"
        } else {
            title = base.title
        }

        var tags = base.tags.filter { HobbyLibrary.allTags.contains($0) }
        if tags.isEmpty {
            tags = [HobbyLibrary.tags(for: category).first ?? category.title]
        }

        return AIPlanDraft(
            title: title,
            summary: base.summary,
            steps: base.steps,
            materials: base.materials,
            tags: tags,
            durationMinutes: base.duration,
            capacity: base.capacity
        )
    }
}
