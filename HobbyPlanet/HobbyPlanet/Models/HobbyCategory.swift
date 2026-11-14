//
//  HobbyCategory.swift
//  HobbyPlanet
//
//  兴趣分类与标签词库。分类是封闭集合（6 类），标签是每个分类下的开放词表，
//  大模型返回的标签会先落到词表里做校验，不在词表内的丢弃，避免“兴趣标签越界”。
//

import SwiftUI

enum HobbyCategory: String, Codable, CaseIterable, Identifiable {
    case handcraft
    case pet
    case food
    case club
    case sport
    case music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .handcraft: return "手作"
        case .pet: return "宠物"
        case .food: return "探店"
        case .club: return "社团"
        case .sport: return "运动"
        case .music: return "音乐"
        }
    }

    var slogan: String {
        switch self {
        case .handcraft: return "把周末做成一件小东西"
        case .pet: return "撸猫遛狗，顺便认识同好"
        case .food: return "校园三公里内的好吃的"
        case .club: return "找组织，也找搭子"
        case .sport: return "夜跑、球局、飞盘"
        case .music: return "排练、live、街唱"
        }
    }

    var symbol: String {
        switch self {
        case .handcraft: return "scissors"
        case .pet: return "pawprint.fill"
        case .food: return "fork.knife"
        case .club: return "person.3.fill"
        case .sport: return "figure.run"
        case .music: return "music.note"
        }
    }

    var tint: Color {
        switch self {
        case .handcraft: return Palette.amber
        case .pet: return Palette.sky
        case .food: return Palette.brand
        case .club: return Palette.violet
        case .sport: return Palette.mint
        case .music: return Palette.rose
        }
    }

    /// 持久化到 JSON 时用到的色值，便于跨端一致
    var tintHex: UInt32 {
        switch self {
        case .handcraft: return 0xE39B2D
        case .pet: return 0x3F8FE0
        case .food: return 0xFF6A3D
        case .club: return 0x7C5CFF
        case .sport: return 0x14A97A
        case .music: return 0xD2538C
        }
    }

    static func from(_ raw: String) -> HobbyCategory {
        HobbyCategory(rawValue: raw) ?? .club
    }
}

/// 标签词库：每个分类 8 个常用标签，引导页与发布页共用
enum HobbyLibrary {
    static let tags: [HobbyCategory: [String]] = [
        .handcraft: ["陶艺", "烘焙", "编织", "拼豆", "印章", "手账", "皮具", "花艺"],
        .pet: ["猫咖", "遛狗", "宠物摄影", "领养", "异宠", "宠物友好店", "救助站", "训犬"],
        .food: ["咖啡", "面包", "烧烤", "川菜", "甜品", "夜宵", "食堂测评", "小众餐厅"],
        .club: ["话剧社", "摄影社", "志愿活动", "读书会", "桌游", "辩论", "支教", "社团招新"],
        .sport: ["夜跑", "羽毛球", "篮球", "飞盘", "游泳", "骑行", "爬山", "健身"],
        .music: ["吉他", "合唱", "livehouse", "街唱", "作曲", "乐队", "黑胶", "音乐节"]
    ]

    static var allTags: [String] {
        HobbyCategory.allCases.flatMap { tags[$0] ?? [] }
    }

    static func tags(for category: HobbyCategory) -> [String] {
        tags[category] ?? []
    }

    /// 标签归一化：去空格、去重、限制数量
    static func normalize(_ raw: [String], limit: Int = 5) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for item in raw {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 8 else { continue }
            if seen.insert(trimmed).inserted {
                result.append(trimmed)
            }
            if result.count >= limit { break }
        }
        return result
    }

    /// 头像选择器里的候选图标
    static let avatarSymbols: [String] = [
        "sparkles", "pawprint.fill", "scissors", "cup.and.saucer.fill",
        "music.note", "figure.run", "camera.fill", "leaf.fill"
    ]
}
