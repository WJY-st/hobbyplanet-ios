//
//  ActivityCards.swift
//  HobbyPlanet
//
//  列表卡片。两种形态：横向滑动的「推荐大卡」与竖向列表的「行卡」。
//  两种卡片共用同一套封面渐变与信息层级，只是信息密度不同。
//

import SwiftUI

// MARK: - 封面

struct ActivityCover: View {
    let activity: HobbyActivity
    var height: CGFloat = 120
    var cornerRadius: CGFloat = 18

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [activity.category.tint.opacity(0.95),
                         activity.category.tint.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 背景水印图标，放大后只露出局部，作为封面图形
            Image(systemName: activity.coverSymbol)
                .font(.system(size: height * 0.78, weight: .bold))
                .foregroundColor(.white.opacity(0.16))
                .offset(x: height * 0.34, y: -height * 0.08)

            HStack(spacing: 6) {
                Image(systemName: activity.category.symbol)
                    .font(.system(size: 10, weight: .bold))
                Text(activity.category.title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.22)))
            .padding(10)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - 推荐大卡

struct FeaturedCard: View {
    let activity: HobbyActivity
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ActivityCover(activity: activity, height: 118, cornerRadius: 0)
                ScoreRing(score: score, size: 46, lineWidth: 5, tint: .white)
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(activity.title)
                    .font(Typo.headline(15))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .topLeading)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(activity.timeText)
                    Text("·")
                    Text(activity.location)
                        .lineLimit(1)
                }
                .font(.system(size: 11.5))
                .foregroundColor(Palette.inkSecondary)

                HStack(spacing: 6) {
                    AvatarStack(participants: activity.participants, size: 22, maxCount: 3)
                    Text("\(activity.joinedCount) 人已加入")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.inkTertiary)
                    Spacer(minLength: 0)
                }
            }
            .padding(13)
        }
        .frame(width: 264)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
}

// MARK: - 列表行卡

struct ActivityRow: View {
    let activity: HobbyActivity
    var score: Int? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(activity.category.tint.opacity(0.14))
                Image(systemName: activity.coverSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(activity.category.tint)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(Typo.headline(15))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(activity.timeText)
                    Text("·")
                    Text(activity.location)
                        .lineLimit(1)
                }
                .font(.system(size: 11.5))
                .foregroundColor(Palette.inkSecondary)

                HStack(spacing: 6) {
                    ForEach(activity.tags.prefix(2), id: \.self) { tag in
                        MiniTag(text: tag, tint: activity.category.tint)
                    }
                    Spacer(minLength: 0)
                    if let score {
                        Text("\(score)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(Palette.brand)
                        Text("同好")
                            .font(.system(size: 9))
                            .foregroundColor(Palette.inkTertiary)
                    } else {
                        Text(activity.seatText)
                            .font(.system(size: 10.5))
                            .foregroundColor(activity.isFull ? Palette.danger : Palette.inkTertiary)
                    }
                }
            }
        }
        .card(padding: 12)
    }
}
