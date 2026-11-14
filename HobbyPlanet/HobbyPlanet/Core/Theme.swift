//
//  Theme.swift
//  HobbyPlanet
//
//  全局设计令牌：颜色、圆角、间距、按钮样式。
//  所有视图只引用这里的语义化色值，不直接写 RGB，便于统一换肤与深色模式适配。
//

import SwiftUI

// MARK: - 十六进制颜色

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: CGFloat(alpha)))
    }

    /// 浅色 / 深色两套取值，交给系统按当前外观自动切换
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - 调色板

enum Palette {
    /// 主品牌色：活力珊瑚橙，用于主按钮、选中态与强调数字
    static let brand = Color(light: 0xFF6A3D, dark: 0xFF7B52)
    /// 品牌色的浅色底，用于标签、提示条
    static let brandSoft = Color(light: 0xFFEDE6, dark: 0x3A241D)

    /// 正文墨色与次级文字
    static let ink = Color(light: 0x1E1B22, dark: 0xF4F1EC)
    static let inkSecondary = Color(light: 0x6F6A76, dark: 0xA8A2AE)
    static let inkTertiary = Color(light: 0x9C96A3, dark: 0x807A86)

    /// 页面底色、卡片底色与分割线
    static let canvas = Color(light: 0xFBF7F2, dark: 0x131116)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1E1B22)
    static let line = Color(light: 0xEDE6DD, dark: 0x2C2833)

    /// 辅助色，用于兴趣分类与图表
    static let amber = Color(light: 0xE39B2D, dark: 0xF0B44F)
    static let sky = Color(light: 0x3F8FE0, dark: 0x6AAFF0)
    static let violet = Color(light: 0x7C5CFF, dark: 0x9C82FF)
    static let mint = Color(light: 0x14A97A, dark: 0x2FCE96)
    static let rose = Color(light: 0xD2538C, dark: 0xEE7BAE)

    /// 语义色
    static let success = Color(light: 0x14A97A, dark: 0x2FCE96)
    static let warning = Color(light: 0xE08A17, dark: 0xF2AC45)
    static let danger = Color(light: 0xD9442E, dark: 0xF26B57)
}

// MARK: - 尺寸与间距

enum Metric {
    static let pagePadding: CGFloat = 20
    static let cardRadius: CGFloat = 22
    static let chipRadius: CGFloat = 14
    static let sectionGap: CGFloat = 24
    static let cardShadowRadius: CGFloat = 18
}

// MARK: - 字体

enum Typo {
    static func hero(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func title(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold)
    }

    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 12.5, weight: .medium)
    static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - 通用样式

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                    .stroke(Palette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }

    /// 统一的首屏标题排版
    func pageTitle() -> some View {
        font(Typo.hero(28))
            .foregroundColor(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 主按钮

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(enabled ? Palette.brand : Palette.inkTertiary.opacity(0.45))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 次要按钮：描边 + 品牌色文字
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Palette.brand)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.brandSoft)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
