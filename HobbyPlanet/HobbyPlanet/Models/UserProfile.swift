//
//  UserProfile.swift
//  HobbyPlanet
//
//  本地用户档案。这个 App 不做账号体系，昵称和兴趣标签都存在本机，
//  只用于个性化推荐与大模型上下文，不涉及任何服务端身份数据。
//

import Foundation

struct UserProfile: Codable, Equatable {
    var nickname: String
    var avatarSymbol: String
    /// 用户选中的兴趣标签，最多 8 个
    var interests: Set<String>
    /// 已报名的活动 id
    var joinedIDs: Set<UUID>
    /// 收藏的活动 id
    var favoriteIDs: Set<UUID>
    var remindBeforeStart: Bool
    /// 是否已经完成引导流程（选择昵称与兴趣）
    var didFinishOnboarding: Bool

    init(nickname: String = "",
         avatarSymbol: String = "sparkles",
         interests: Set<String> = [],
         joinedIDs: Set<UUID> = [],
         favoriteIDs: Set<UUID> = [],
         remindBeforeStart: Bool = true,
         didFinishOnboarding: Bool = false) {
        self.nickname = nickname
        self.avatarSymbol = avatarSymbol
        self.interests = interests
        self.joinedIDs = joinedIDs
        self.favoriteIDs = favoriteIDs
        self.remindBeforeStart = remindBeforeStart
        self.didFinishOnboarding = didFinishOnboarding
    }

    var displayName: String {
        nickname.isEmpty ? "同学" : nickname
    }

    var interestCount: Int { interests.count }

    /// 兴趣分布：把标签映射回分类，用于雷达图与“兴趣画像”
    func interestDistribution() -> [HobbyCategory: Int] {
        var result: [HobbyCategory: Int] = [:]
        for category in HobbyCategory.allCases {
            let library = Set(HobbyLibrary.tags(for: category))
            let hit = interests.filter { library.contains($0) }.count
            if hit > 0 {
                result[category] = hit
            }
        }
        return result
    }

    /// 用户最感兴趣的三个分类，按命中标签数排序
    var topCategories: [HobbyCategory] {
        interestDistribution()
            .sorted { $0.value == $1.value ? $0.key.rawValue < $1.key.rawValue : $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
}
