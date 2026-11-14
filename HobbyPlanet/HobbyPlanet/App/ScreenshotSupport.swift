//
//  ScreenshotSupport.swift
//  HobbyPlanet
//
//  给 CI 截图用的「确定性启动状态」。
//
//  背景：GitHub Actions 的 macOS 机器可以启动 iOS 模拟器，但没法像人一样点击界面。
//  这里的做法是给 App 传一个启动参数（例如 -screenshot detail），让它在启动后
//  直接进入指定页面、预置好昵称与兴趣、必要时自动触发一次 AI 生成，
//  于是 CI 里 `simctl launch` + `simctl io screenshot` 就能拿到稳定一致的界面图。
//
//  安全性：只有 DEBUG 构建才会解析启动参数；Release 构建里 current 恒为 nil，
//  这些分支永远不会执行，App 正常启动的行为不变。
//

import Foundation

enum ScreenshotScenario: String, CaseIterable {
    case onboarding
    case discover
    case detail
    case publish
    case aiplan
    case radar
    case assistant
    case profile

    /// 从启动参数里读取 -screenshot <场景名>
    static var current: ScreenshotScenario? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"),
              index + 1 < arguments.count else {
            return nil
        }
        return ScreenshotScenario(rawValue: arguments[index + 1])
        #else
        return nil
        #endif
    }

    /// 除引导页外，其余场景都直接进入主界面
    var needsProfile: Bool { self != .onboarding }

    /// 初始选中的标签页
    var initialTab: MainTabView.Tab {
        switch self {
        case .radar: return .radar
        case .assistant: return .assistant
        case .profile: return .profile
        default: return .discover
        }
    }

    /// 助手页自动提问的内容
    var autoQuestion: String? {
        self == .assistant ? "周末有什么活动推荐？" : nil
    }

    /// AI 策划页自动填入的想法
    var autoIdea: String? {
        self == .aiplan ? "周五晚上想在操场跑个五公里，配速慢一点" : nil
    }
}

extension ProfileStore {
    /// 截图用：写一份固定的用户档案，保证每张图内容一致
    func applyScreenshotProfile() {
        guard ScreenshotScenario.current != nil else { return }
        var updated = profile
        updated.nickname = "林同学"
        updated.avatarSymbol = "sparkles"
        updated.interests = ["陶艺", "拼豆", "咖啡", "夜跑"]
        updated.didFinishOnboarding = true
        profile = updated
    }

    /// 截图用：清空档案，回到引导页
    func resetForScreenshot() {
        guard ScreenshotScenario.current != nil else { return }
        profile = UserProfile()
    }
}
