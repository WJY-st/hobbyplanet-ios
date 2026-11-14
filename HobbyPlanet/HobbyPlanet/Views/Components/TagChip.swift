//
//  TagChip.swift
//  HobbyPlanet
//
//  兴趣标签胶囊。选中 / 未选中两种状态，用同一套圆角与内边距，
//  保证引导页、发布页、雷达页里的标签视觉一致。
//

import SwiftUI

struct TagChip: View {
    let text: String
    var tint: Color = Palette.brand
    var selected: Bool = false
    var showPlus: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if showPlus && !selected {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(Typo.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .foregroundColor(selected ? .white : tint)
        .background(
            Capsule(style: .continuous)
                .fill(selected ? tint : tint.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(selected ? Color.clear : tint.opacity(0.22), lineWidth: 1)
        )
    }
}

/// 只读的小标签，用在卡片上，尺寸比 TagChip 更小
struct MiniTag: View {
    let text: String
    var tint: Color = Palette.inkSecondary

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(tint)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tint.opacity(0.10))
            )
    }
}
