//
//  RootView.swift
//  HobbyPlanet
//
//  根视图与主标签栏。
//  路由集中在一个 AppRoute 枚举里，页面之间只传“标识”（UUID），
//  真正的数据由目标页自己从 Store 取，避免把整个对象塞进导航路径。
//

import SwiftUI

/// 全局路由。Hashable 是 NavigationStack 的前提条件。
enum AppRoute: Hashable {
    case activity(UUID)
    case myList(MyListFilter)
    case settings
    case interestEditor

    enum MyListFilter: String, Hashable {
        case joined = "我报名的"
        case hosted = "我发起的"
        case favorite = "我的收藏"
    }
}

struct RootView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            if profileStore.profile.didFinishOnboarding {
                MainTabView(initialTab: ScreenshotScenario.current?.initialTab ?? .discover)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: profileStore.profile.didFinishOnboarding)
        .onAppear(perform: prepareScreenshotState)
    }

    /// CI 截图时预置用户档案；正常启动时 ScreenshotScenario.current 为 nil，什么也不做
    private func prepareScreenshotState() {
        guard let scenario = ScreenshotScenario.current else { return }
        if scenario.needsProfile {
            profileStore.applyScreenshotProfile()
        } else {
            profileStore.resetForScreenshot()
        }
    }
}

struct MainTabView: View {
    enum Tab: Hashable {
        case discover
        case radar
        case assistant
        case profile
    }

    @State private var selection: Tab

    init(initialTab: Tab = .discover) {
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selection) {
            DiscoverView()
                .tabItem {
                    Label("发现", systemImage: "sparkles")
                }
                .tag(Tab.discover)

            RadarView()
                .tabItem {
                    Label("同好雷达", systemImage: "dot.radiowaves.left.and.right")
                }
                .tag(Tab.radar)

            AssistantView(autoQuestion: ScreenshotScenario.current?.autoQuestion ?? "")
                .tabItem {
                    Label("AI 助手", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(Tab.assistant)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
        .tint(Palette.brand)
    }
}
