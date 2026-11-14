//
//  Haptics.swift
//  HobbyPlanet
//
//  轻量触感反馈封装。iOS 的 UIFeedbackGenerator 需要显式 prepare 才能在下一次触发时
//  立即响应，这里统一在调用前 prepare，避免第一次点击没有震动。
//

import UIKit

enum Haptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func select() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}
