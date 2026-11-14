//
//  ProfileStore.swift
//  HobbyPlanet
//
//  用户档案与设置的持久化。
//  - 昵称、兴趣、收藏等小体量数据放 UserDefaults（一个 plist，启动即可读）
//  - API Key 放钥匙串（见 KeychainHelper）
//  - 外观偏好用 @Published 驱动根视图切换
//

import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class ProfileStore: ObservableObject {
    @Published var profile: UserProfile {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private static let profileKey = "hobbyplanet.profile.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: ProfileStore.profileKey),
           let decoded = try? JSONCoding.decoder.decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }

    private func persist() {
        guard let data = try? JSONCoding.encoder.encode(profile) else { return }
        defaults.set(data, forKey: ProfileStore.profileKey)
    }

    // MARK: - 引导

    func finishOnboarding(nickname: String, interests: Set<String>, avatar: String) {
        profile.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.interests = interests
        profile.avatarSymbol = avatar
        profile.didFinishOnboarding = true
    }

    // MARK: - 兴趣

    func toggleInterest(_ tag: String) {
        if profile.interests.contains(tag) {
            profile.interests.remove(tag)
        } else if profile.interests.count < 8 {
            profile.interests.insert(tag)
        }
    }

    func isInterested(in tag: String) -> Bool {
        profile.interests.contains(tag)
    }

    // MARK: - 收藏

    func toggleFavorite(_ id: UUID) {
        if profile.favoriteIDs.contains(id) {
            profile.favoriteIDs.remove(id)
        } else {
            profile.favoriteIDs.insert(id)
        }
    }

    func isFavorite(_ id: UUID) -> Bool {
        profile.favoriteIDs.contains(id)
    }

    // MARK: - 报名记录

    func markJoined(_ id: UUID) { profile.joinedIDs.insert(id) }

    func unmarkJoined(_ id: UUID) { profile.joinedIDs.remove(id) }

    func hasJoined(_ id: UUID) -> Bool { profile.joinedIDs.contains(id) }

    // MARK: - 重置

    func resetProfile() {
        profile = UserProfile()
    }
}

final class SettingsStore: ObservableObject {
    @Published var baseURL: String {
        didSet { defaults.set(baseURL, forKey: Keys.baseURL) }
    }

    @Published var model: String {
        didSet { defaults.set(model, forKey: Keys.model) }
    }

    @Published var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// 从钥匙串读取，内存中只保留解密后的字符串
    @Published private(set) var apiKey: String

    private let defaults: UserDefaults

    private enum Keys {
        static let baseURL = "hobbyplanet.baseurl"
        static let model = "hobbyplanet.model"
        static let appearance = "hobbyplanet.appearance"
    }

    static let defaultBaseURL = "https://api.deepseek.com/v1/chat/completions"
    static let defaultModel = "deepseek-chat"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.baseURL = defaults.string(forKey: Keys.baseURL) ?? SettingsStore.defaultBaseURL
        self.model = defaults.string(forKey: Keys.model) ?? SettingsStore.defaultModel
        let storedMode = defaults.string(forKey: Keys.appearance) ?? AppearanceMode.system.rawValue
        self.appearance = AppearanceMode(rawValue: storedMode) ?? .system
        self.apiKey = KeychainHelper.read() ?? ""
    }

    var hasKey: Bool { !apiKey.isEmpty }

    func updateKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = trimmed
        if trimmed.isEmpty {
            KeychainHelper.delete()
        } else {
            KeychainHelper.save(trimmed)
        }
    }

    /// 界面上只显示前 6 位与后 4 位
    var maskedKey: String {
        guard apiKey.count > 10 else { return apiKey.isEmpty ? "未配置" : "已配置" }
        return "\(apiKey.prefix(6))••••••\(apiKey.suffix(4))"
    }
}
