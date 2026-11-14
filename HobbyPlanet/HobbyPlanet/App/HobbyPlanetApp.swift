//
//  HobbyPlanetApp.swift
//  HobbyPlanet
//
//  应用入口。三个 Store 在这里创建并注入环境：
//  ActivityStore 管活动数据、ProfileStore 管用户档案、SettingsStore 管接口与外观。
//  整个 App 只有这一处创建它们，视图里通过 @EnvironmentObject 取用。
//

import SwiftUI

@main
struct HobbyPlanetApp: App {
    @StateObject private var activityStore = ActivityStore()
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(activityStore)
                .environmentObject(profileStore)
                .environmentObject(settingsStore)
                .tint(Palette.brand)
                .preferredColorScheme(settingsStore.appearance.colorScheme)
        }
    }
}
