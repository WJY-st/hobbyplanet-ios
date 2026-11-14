//
//  AvatarView.swift
//  HobbyPlanet
//
//  圆形头像。App 不做真实头像上传，用 SF Symbol + 分类色组合，
//  既省掉相册权限，也能保证一屏里每个头像都有区分度。
//

import SwiftUI

struct AvatarView: View {
    let symbol: String
    var size: CGFloat = 40
    var tint: Color = Palette.brand
    var borderWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.10)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(tint)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(Palette.surface, lineWidth: borderWidth)
        )
    }
}

/// 一排重叠头像，用于展示已报名的人
struct AvatarStack: View {
    let participants: [Participant]
    var size: CGFloat = 28
    var maxCount: Int = 4
    var tint: Color = Palette.sky

    var body: some View {
        HStack(spacing: -size * 0.32) {
            ForEach(participants.prefix(maxCount)) { participant in
                AvatarView(symbol: participant.symbol, size: size, tint: tint)
            }
            if participants.count > maxCount {
                ZStack {
                    Circle().fill(Palette.line)
                    Text("+\(participants.count - maxCount)")
                        .font(.system(size: size * 0.34, weight: .bold))
                        .foregroundColor(Palette.inkSecondary)
                }
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Palette.surface, lineWidth: 2))
            }
        }
    }
}
