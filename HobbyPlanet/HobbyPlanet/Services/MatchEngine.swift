//
//  MatchEngine.swift
//  HobbyPlanet
//
//  “同好度”算法：把兴趣重合、分类偏好、时间偏好、新鲜度和余位折算成 0-99 的分数。
//  这是 App 的微创新点之一 —— 推荐理由由本地算法给出，大模型只负责把它讲成人话，
//  避免“AI 说什么就信什么”的随机推荐。
//

import Foundation

struct MatchResult: Identifiable {
    let activity: HobbyActivity
    let score: Int
    let reasons: [String]

    var id: UUID { activity.id }

    /// 分数对应的口语化等级
    var level: String {
        switch score {
        case 80...: return "高度同好"
        case 60..<80: return "比较合适"
        case 40..<60: return "可以试试"
        default: return "新领域"
        }
    }
}

enum MatchEngine {
    /// 权重说明：兴趣重合 55 分、分类偏好 15 分、时间 15 分、新鲜度 8 分、余位 7 分
    static func evaluate(activity: HobbyActivity, profile: UserProfile) -> MatchResult {
        var score: Double = 0
        var reasons: [String] = []
        let interests = profile.interests

        // 1. 兴趣标签重合度（覆盖率 = 命中标签 / 活动标签总数）
        if activity.tags.isEmpty {
            score += 20
        } else {
            let shared = activity.tags.filter { interests.contains($0) }
            let coverage = Double(shared.count) / Double(activity.tags.count)
            score += coverage * 55
            if let first = shared.first {
                reasons.append("你也喜欢「\(first)」")
            }
        }

        // 2. 分类偏好
        if profile.topCategories.contains(activity.category) {
            score += 15
            if reasons.count < 3 {
                reasons.append("\(activity.category.title)是你常去的方向")
            }
        }

        // 3. 时间偏好：放学后（18 点后）与上午，以及周末
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: activity.startAt)
        if hour >= 18 || hour < 10 {
            score += 8
        }
        if calendar.isDateInWeekend(activity.startAt) {
            score += 7
            if reasons.count < 3 {
                reasons.append("安排在周末，时间好凑")
            }
        }

        // 4. 新鲜度：三天内发布
        let age = Date().timeIntervalSince(activity.createdAt)
        if age >= 0 && age < 3 * 86_400 {
            score += 8
            if reasons.count < 3 {
                reasons.append("刚发布不久")
            }
        }

        // 5. 余位：还有位置才值得推荐
        if !activity.isFull {
            score += 7
            if activity.remainingSeats <= 3 && reasons.count < 3 {
                reasons.append("只剩 \(activity.remainingSeats) 个位置")
            }
        }

        let clamped = min(99, max(5, Int(score.rounded())))
        if reasons.isEmpty {
            reasons.append("换个领域试试，也许会有惊喜")
        }
        return MatchResult(activity: activity, score: clamped, reasons: Array(reasons.prefix(3)))
    }

    static func ranked(_ activities: [HobbyActivity], profile: UserProfile) -> [MatchResult] {
        activities
            .map { evaluate(activity: $0, profile: profile) }
            .sorted {
                if $0.score == $1.score {
                    return $0.activity.startAt < $1.activity.startAt
                }
                return $0.score > $1.score
            }
    }

    /// 用户兴趣分布，给雷达图用。没有标签时返回全 0，界面显示引导文案。
    static func distribution(of profile: UserProfile) -> [(category: HobbyCategory, value: Double)] {
        let raw = profile.interestDistribution()
        let maxValue = raw.values.max() ?? 0
        return HobbyCategory.allCases.map { category in
            let count = raw[category] ?? 0
            let value = maxValue > 0 ? Double(count) / Double(maxValue) : 0
            return (category, value)
        }
    }
}
