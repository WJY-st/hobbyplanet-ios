//
//  HobbyActivity.swift
//  HobbyPlanet
//
//  核心业务模型：一场同好活动。整个 App 的列表、详情、报名、匹配都围绕它展开。
//  解码时对每个字段都做了兜底，任何一条脏数据都不应该让整个列表崩掉。
//

import Foundation

// MARK: - 参与者

struct Participant: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var symbol: String
    var joinedAt: Date

    init(id: UUID = UUID(), name: String, symbol: String = "person.fill", joinedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.joinedAt = joinedAt
    }
}

// MARK: - 活动

struct HobbyActivity: Identifiable, Hashable, Codable {
    var id: UUID
    var title: String
    var summary: String
    var category: HobbyCategory
    var tags: [String]
    var startAt: Date
    var durationMinutes: Int
    var location: String
    var capacity: Int
    var hostName: String
    var hostID: UUID
    var coverSymbol: String
    var steps: [String]
    var materials: [String]
    var participants: [Participant]
    var createdAt: Date
    /// 是否为当前用户发起（本地数据，不上服务器）
    var isMine: Bool

    init(id: UUID = UUID(),
         title: String,
         summary: String,
         category: HobbyCategory,
         tags: [String],
         startAt: Date,
         durationMinutes: Int = 120,
         location: String,
         capacity: Int = 12,
         hostName: String,
         hostID: UUID = UUID(),
         coverSymbol: String? = nil,
         steps: [String] = [],
         materials: [String] = [],
         participants: [Participant] = [],
         createdAt: Date = Date(),
         isMine: Bool = false) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.tags = tags
        self.startAt = startAt
        self.durationMinutes = durationMinutes
        self.location = location
        self.capacity = capacity
        self.hostName = hostName
        self.hostID = hostID
        self.coverSymbol = coverSymbol ?? category.symbol
        self.steps = steps
        self.materials = materials
        self.participants = participants
        self.createdAt = createdAt
        self.isMine = isMine
    }

    // MARK: 派生属性

    var joinedCount: Int { participants.count }

    var isFull: Bool { participants.count >= capacity }

    var remainingSeats: Int { max(0, capacity - participants.count) }

    var endAt: Date { startAt.addingTimeInterval(Double(durationMinutes) * 60) }

    var isFinished: Bool { endAt < Date() }

    var fillRatio: Double {
        guard capacity > 0 else { return 0 }
        return min(1, Double(participants.count) / Double(capacity))
    }

    func contains(tag: String) -> Bool {
        tags.contains(tag)
    }

    // MARK: 容错解码

    enum CodingKeys: String, CodingKey {
        case id, title, summary, category, tags, startAt, durationMinutes
        case location, capacity, hostName, hostID, coverSymbol, steps
        case materials, participants, createdAt, isMine
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = (try? container.decodeIfPresent(UUID.self, forKey: .id)) .flatMap { $0 } ?? UUID()
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) .flatMap { $0 } ?? "未命名活动"
        summary = (try? container.decodeIfPresent(String.self, forKey: .summary)) .flatMap { $0 } ?? ""
        category = HobbyCategory.from((try? container.decodeIfPresent(String.self, forKey: .category)) .flatMap { $0 } ?? "")
        tags = (try? container.decodeIfPresent([String].self, forKey: .tags)) .flatMap { $0 } ?? []
        startAt = (try? container.decodeIfPresent(Date.self, forKey: .startAt)) .flatMap { $0 } ?? Date().addingTimeInterval(86_400)
        durationMinutes = (try? container.decodeIfPresent(Int.self, forKey: .durationMinutes)) .flatMap { $0 } ?? 120
        location = (try? container.decodeIfPresent(String.self, forKey: .location)) .flatMap { $0 } ?? "待定"
        capacity = (try? container.decodeIfPresent(Int.self, forKey: .capacity)) .flatMap { $0 } ?? 12
        hostName = (try? container.decodeIfPresent(String.self, forKey: .hostName)) .flatMap { $0 } ?? "匿名同学"
        hostID = (try? container.decodeIfPresent(UUID.self, forKey: .hostID)) .flatMap { $0 } ?? UUID()
        coverSymbol = (try? container.decodeIfPresent(String.self, forKey: .coverSymbol)) .flatMap { $0 } ?? category.symbol
        steps = (try? container.decodeIfPresent([String].self, forKey: .steps)) .flatMap { $0 } ?? []
        materials = (try? container.decodeIfPresent([String].self, forKey: .materials)) .flatMap { $0 } ?? []
        participants = (try? container.decodeIfPresent([Participant].self, forKey: .participants)) .flatMap { $0 } ?? []
        createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) .flatMap { $0 } ?? Date()
        isMine = (try? container.decodeIfPresent(Bool.self, forKey: .isMine)) .flatMap { $0 } ?? false
    }
}

// MARK: - 展示用扩展

extension HobbyActivity {
    var timeText: String { Fmt.activityTime(startAt) }

    var durationText: String { Fmt.duration(minutes: durationMinutes) }

    var seatText: String {
        if isFinished { return "已结束" }
        if isFull { return "已满员" }
        return "还剩 \(remainingSeats) 个位置"
    }

    /// 卡片上显示的两行简介，超长截断，不依赖 Text 的默认行数限制
    var shortSummary: String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 46 { return trimmed }
        return String(trimmed.prefix(46)) + "…"
    }
}
