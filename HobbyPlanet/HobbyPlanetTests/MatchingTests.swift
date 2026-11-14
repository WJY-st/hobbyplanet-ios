//
//  MatchingTests.swift
//  HobbyPlanetTests
//
//  同好度算法的单元测试：验证排序单调性、边界值与理由生成。
//

import XCTest
@testable import HobbyPlanet

final class MatchingTests: XCTestCase {

    private func makeActivity(tags: [String],
                              category: HobbyCategory = .handcraft,
                              daysFromNow: Double = 2,
                              hoursFromNow: Double = 48,
                              capacity: Int = 10,
                              participantCount: Int = 1) -> HobbyActivity {
        let participants = (0..<participantCount).map { index in
            Participant(name: "同学\(index)")
        }
        return HobbyActivity(
            title: "测试活动 \(tags.joined(separator: "-"))",
            summary: "用于测试的活动",
            category: category,
            tags: tags,
            startAt: Date().addingTimeInterval(hoursFromNow * 3600),
            durationMinutes: 120,
            location: "测试地点",
            capacity: capacity,
            hostName: "测试发起人",
            participants: participants,
            createdAt: Date().addingTimeInterval(-daysFromNow * 86_400)
        )
    }

    func testScoreIsClamped() {
        var profile = UserProfile()
        profile.interests = ["陶艺", "烘焙", "拼豆"]
        let activity = makeActivity(tags: ["陶艺", "烘焙"], category: .handcraft)
        let result = MatchEngine.evaluate(activity: activity, profile: profile)

        XCTAssertGreaterThanOrEqual(result.score, 5)
        XCTAssertLessThanOrEqual(result.score, 99)
        XCTAssertFalse(result.reasons.isEmpty)
    }

    func testInterestsRaiseScore() {
        let activity = makeActivity(tags: ["陶艺", "拼豆"], category: .handcraft, hoursFromNow: 30)

        var without = UserProfile()
        without.interests = ["夜跑"]

        var with = UserProfile()
        with.interests = ["陶艺", "拼豆"]

        let low = MatchEngine.evaluate(activity: activity, profile: without).score
        let high = MatchEngine.evaluate(activity: activity, profile: with).score

        XCTAssertGreaterThan(high, low, "命中兴趣标签时同好度应更高")
    }

    func testRankingIsDescending() {
        var profile = UserProfile()
        profile.interests = ["陶艺", "咖啡"]

        let activities = [
            makeActivity(tags: ["陶艺"], category: .handcraft, hoursFromNow: 10),
            makeActivity(tags: ["篮球"], category: .sport, hoursFromNow: 20),
            makeActivity(tags: ["咖啡"], category: .food, hoursFromNow: 30)
        ]

        let ranked = MatchEngine.ranked(activities, profile: profile)
        XCTAssertEqual(ranked.count, 3)

        for index in 1..<ranked.count {
            XCTAssertGreaterThanOrEqual(ranked[index - 1].score, ranked[index].score)
        }
        XCTAssertTrue(ranked.first!.activity.tags.contains("陶艺") || ranked.first!.activity.tags.contains("咖啡"))
    }

    func testFullActivityLosesSeatBonus() {
        var profile = UserProfile()
        profile.interests = ["飞盘"]

        let open = makeActivity(tags: ["飞盘"], category: .sport, capacity: 10, participantCount: 2)
        let full = makeActivity(tags: ["飞盘"], category: .sport, capacity: 4, participantCount: 4)

        let openScore = MatchEngine.evaluate(activity: open, profile: profile).score
        let fullScore = MatchEngine.evaluate(activity: full, profile: profile).score

        XCTAssertGreaterThan(openScore, fullScore)
    }

    func testDistributionNormalized() {
        var profile = UserProfile()
        profile.interests = ["陶艺", "烘焙", "拼豆", "夜跑"]

        let distribution = MatchEngine.distribution(of: profile)
        XCTAssertEqual(distribution.count, HobbyCategory.allCases.count)
        XCTAssertEqual(distribution.map { $0.value }.max() ?? 0, 1.0, accuracy: 0.001)
    }
}
