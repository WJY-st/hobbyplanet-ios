//
//  EmptyStateView.swift
//  HobbyPlanet
//
//  空状态占位。列表为空时给出“下一步该做什么”，而不是一句冷冰冰的“暂无数据”。
//

import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.brandSoft)
                    .frame(width: 74, height: 74)
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Palette.brand)
            }

            Text(title)
                .font(Typo.headline(16))
                .foregroundColor(Palette.ink)

            Text(message)
                .font(Typo.caption)
                .foregroundColor(Palette.inkTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Palette.brand))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
    }
}
