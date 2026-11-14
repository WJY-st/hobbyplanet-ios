//
//  ActivityStore.swift
//  HobbyPlanet
//
//  活动数据的唯一来源（single source of truth）。
//  内存里是 @Published 数组，落盘是 Application Support 下的一个 JSON 文件，
//  采用 .atomic 写入：先写临时文件再原子替换，写一半被杀进程也不会留下半个 JSON。
//

import Foundation
import Combine

enum JSONCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

final class ActivityStore: ObservableObject {
    @Published private(set) var activities: [HobbyActivity] = []

    /// 最后一次读写失败的信息，界面层用它弹提示
    @Published var lastErrorMessage: String?

    private let fileURL: URL
    private let encoder = JSONCoding.encoder
    private let decoder = JSONCoding.decoder

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? ActivityStore.defaultFileURL()
        load()
    }

    // MARK: - 路径

    private static func defaultFileURL() -> URL {
        let manager = FileManager.default
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = base.appendingPathComponent("HobbyPlanet", isDirectory: true)
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("activities.json")
    }

    // MARK: - 查询

    var upcoming: [HobbyActivity] {
        activities
            .filter { !$0.isFinished }
            .sorted { $0.startAt < $1.startAt }
    }

    func activity(with id: UUID) -> HobbyActivity? {
        activities.first { $0.id == id }
    }

    func activities(hostedBy name: String) -> [HobbyActivity] {
        activities.filter { $0.isMine && $0.hostName == name }
    }

    // MARK: - 修改

    func add(_ activity: HobbyActivity) {
        activities.insert(activity, at: 0)
        save()
    }

    func update(_ activity: HobbyActivity) {
        guard let index = activities.firstIndex(where: { $0.id == activity.id }) else { return }
        activities[index] = activity
        save()
    }

    func delete(id: UUID) {
        activities.removeAll { $0.id == id }
        save()
    }

    /// 报名 / 取消报名。返回修改后的活动，方便调用方立即刷新详情页。
    @discardableResult
    func toggleJoin(id: UUID, participant: Participant) -> HobbyActivity? {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return nil }

        if let joinedIndex = activities[index].participants.firstIndex(where: {
            // 本地用户每次点报名都会新建一个 Participant，所以除了 id 还要按昵称兜底匹配
            $0.id == participant.id || $0.name == participant.name
        }) {
            activities[index].participants.remove(at: joinedIndex)
        } else {
            guard !activities[index].isFull else {
                lastErrorMessage = "这个活动已经满员了"
                return activities[index]
            }
            activities[index].participants.append(participant)
        }

        save()
        return activities[index]
    }

    // MARK: - 持久化

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            activities = SeedData.activities()
            save()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode([HobbyActivity].self, from: data)
            activities = decoded
        } catch {
            // 文件存在但解析失败：备份坏文件，回退到示例数据，保证 App 可用
            let backup = fileURL.deletingLastPathComponent()
                .appendingPathComponent("activities.broken.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: fileURL, to: backup)
            activities = SeedData.activities()
            lastErrorMessage = "本地数据损坏，已恢复为示例数据"
            save()
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(activities)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            lastErrorMessage = "保存活动失败：\(error.localizedDescription)"
        }
    }

    /// 设置页“清除本地数据”使用
    func resetToSeed() {
        activities = SeedData.activities()
        save()
    }
}
