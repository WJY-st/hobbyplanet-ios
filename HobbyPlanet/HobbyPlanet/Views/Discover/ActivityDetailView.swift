//
//  ActivityDetailView.swift
//  HobbyPlanet
//
//  活动详情。页面只拿到一个 UUID，所有内容都从 Store 里查，
//  因此在别处（比如“我的收藏”）删掉或改了活动，详情页会自然刷新。
//

import SwiftUI

struct ActivityDetailView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore

    let activityID: UUID

    @State private var toast: String?

    private var activity: HobbyActivity? {
        store.activity(with: activityID)
    }

    private var match: MatchResult? {
        guard let activity else { return nil }
        return MatchEngine.evaluate(activity: activity, profile: profileStore.profile)
    }

    private var hasJoined: Bool {
        profileStore.hasJoined(activityID)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            if let activity {
                content(activity)
                if let toast {
                    toastView(toast)
                }
            } else {
                EmptyStateView(symbol: "questionmark.circle",
                               title: "活动不见了",
                               message: "它可能已经被发起人删除，返回列表看看别的吧。")
            }
        }
        .navigationTitle("活动详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let activity {
                    ShareLink(item: shareText(activity)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - 主体

    private func content(_ activity: HobbyActivity) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ActivityCover(activity: activity, height: 190, cornerRadius: 0)
                    .padding(.horizontal, -Metric.pagePadding)
                    .padding(.top, -8)

                titleBlock(activity)
                infoGrid(activity)
                introBlock(activity)

                if !activity.steps.isEmpty {
                    stepsBlock(activity)
                }
                if !activity.materials.isEmpty {
                    materialsBlock(activity)
                }

                participantsBlock(activity)

                if let match {
                    matchBlock(match)
                }

                hostBlock(activity)
            }
            .padding(.horizontal, Metric.pagePadding)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar(activity)
        }
    }

    private func titleBlock(_ activity: HobbyActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                MiniTag(text: activity.category.title, tint: activity.category.tint)
                MiniTag(text: activity.seatText, tint: activity.isFull ? Palette.danger : Palette.mint)
                Spacer()
            }

            Text(activity.title)
                .font(Typo.hero(24))
                .foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 11))
                Text(Fmt.countdown(to: activity.startAt))
                Text("·")
                Text("\(activity.joinedCount)/\(activity.capacity) 人")
            }
            .font(Typo.caption)
            .foregroundColor(Palette.brand)
        }
        .padding(.top, 4)
    }

    private func infoGrid(_ activity: HobbyActivity) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                  spacing: 10) {
            infoTile(icon: "calendar", title: "时间", value: activity.timeText)
            infoTile(icon: "hourglass", title: "时长", value: activity.durationText)
            infoTile(icon: "mappin.and.ellipse", title: "地点", value: activity.location)
            infoTile(icon: "person.2.fill", title: "名额", value: "\(activity.capacity) 人")
        }
    }

    private func infoTile(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Palette.brand)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Palette.brandSoft))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10.5))
                    .foregroundColor(Palette.inkTertiary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 12)
    }

    private func introBlock(_ activity: HobbyActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "活动介绍")
            Text(activity.summary)
                .font(Typo.body)
                .foregroundColor(Palette.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(activity.tags, id: \.self) { tag in
                    MiniTag(text: tag, tint: activity.category.tint)
                }
            }
            .padding(.top, 2)
        }
    }

    private func stepsBlock(_ activity: HobbyActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "活动流程", subtitle: "\(activity.steps.count) 个环节")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(activity.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(index == 0 ? Palette.brand : Palette.brandSoft)
                                    .frame(width: 24, height: 24)
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(index == 0 ? .white : Palette.brand)
                            }
                            if index != activity.steps.count - 1 {
                                Rectangle()
                                    .fill(Palette.line)
                                    .frame(width: 1.5)
                                    .frame(minHeight: 22)
                            }
                        }

                        Text(step)
                            .font(.system(size: 14))
                            .foregroundColor(Palette.ink)
                            .padding(.top, 3)
                            .padding(.bottom, index == activity.steps.count - 1 ? 0 : 14)

                        Spacer(minLength: 0)
                    }
                }
            }
            .card(padding: 14)
        }
    }

    private func materialsBlock(_ activity: HobbyActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "需要带的东西", subtitle: "没有也能来，只是体验会差一点")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                ForEach(activity.materials, id: \.self) { item in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text(item)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                    .foregroundColor(Palette.inkSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Palette.surface)
                    )
                }
            }
        }
    }

    private func participantsBlock(_ activity: HobbyActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "已报名", subtitle: "\(activity.joinedCount) 人，来自不同专业")

            if activity.participants.isEmpty {
                Text("还没有人报名，来做第一个吧。")
                    .font(Typo.caption)
                    .foregroundColor(Palette.inkTertiary)
                    .card(padding: 14)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    AvatarStack(participants: activity.participants,
                                size: 34,
                                maxCount: 6,
                                tint: activity.category.tint)

                    ProgressView(value: activity.fillRatio)
                        .tint(activity.category.tint)

                    Text(activity.seatText)
                        .font(.system(size: 11))
                        .foregroundColor(Palette.inkTertiary)
                }
                .card(padding: 14)
            }
        }
    }

    private func matchBlock(_ match: MatchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ScoreRing(score: match.score, size: 58, lineWidth: 6)
                VStack(alignment: .leading, spacing: 3) {
                    Text(match.level)
                        .font(Typo.headline(15))
                        .foregroundColor(Palette.ink)
                    Text("基于你的兴趣标签与时间偏好计算")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.inkTertiary)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(match.reasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Palette.brand)
                            .padding(.top, 3)
                        Text(reason)
                            .font(.system(size: 12.5))
                            .foregroundColor(Palette.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .card(padding: 14)
    }

    private func hostBlock(_ activity: HobbyActivity) -> some View {
        HStack(spacing: 10) {
            AvatarView(symbol: activity.coverSymbol, size: 38, tint: activity.category.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("发起人 · \(activity.hostName)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Palette.ink)
                Text("发布于 \(Fmt.relative(activity.createdAt))")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.inkTertiary)
            }
            Spacer()
            if activity.isMine {
                MiniTag(text: "我发起的", tint: Palette.violet)
            }
        }
        .card(padding: 12)
    }

    // MARK: - 底部操作条

    private func bottomBar(_ activity: HobbyActivity) -> some View {
        HStack(spacing: 10) {
            Button {
                Haptics.tap()
                profileStore.toggleFavorite(activity.id)
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: profileStore.isFavorite(activity.id) ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                    Text(profileStore.isFavorite(activity.id) ? "已收藏" : "收藏")
                        .font(.system(size: 9))
                }
                .foregroundColor(profileStore.isFavorite(activity.id) ? Palette.rose : Palette.inkSecondary)
                .frame(width: 54, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                toggleJoin(activity)
            } label: {
                Text(buttonTitle(activity))
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !activity.isFinished && !(activity.isFull && !hasJoined)))
            .disabled(activity.isFinished || (activity.isFull && !hasJoined))
        }
        .padding(.horizontal, Metric.pagePadding)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Palette.surface
                .opacity(0.96)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func buttonTitle(_ activity: HobbyActivity) -> String {
        if activity.isFinished { return "活动已结束" }
        if hasJoined { return "取消报名" }
        if activity.isFull { return "名额已满" }
        return "立即报名"
    }

    // MARK: - 行为

    private func toggleJoin(_ activity: HobbyActivity) {
        if hasJoined {
            let participant = Participant(name: profileStore.profile.displayName,
                                          symbol: profileStore.profile.avatarSymbol)
            store.toggleJoin(id: activity.id, participant: participant)
            profileStore.unmarkJoined(activity.id)
            Haptics.tap()
            showToast("已取消报名")
            return
        }

        guard !activity.isFull else {
            Haptics.warning()
            showToast("名额已满，可以先收藏等有人退出")
            return
        }

        let participant = Participant(name: profileStore.profile.displayName,
                                      symbol: profileStore.profile.avatarSymbol)
        store.toggleJoin(id: activity.id, participant: participant)
        profileStore.markJoined(activity.id)
        Haptics.success()
        showToast("报名成功，记得准时到场")
    }

    private func showToast(_ text: String) {
        withAnimation(.easeOut(duration: 0.2)) { toast = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeIn(duration: 0.2)) { toast = nil }
        }
    }

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Capsule().fill(Palette.ink.opacity(0.92)))
            .padding(.bottom, 92)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func shareText(_ activity: HobbyActivity) -> String {
        """
        【同好星球】\(activity.title)
        \(activity.timeText) · \(activity.location)
        \(activity.summary)
        已有 \(activity.joinedCount) 人报名，还差 \(activity.remainingSeats) 个同好。
        """
    }
}
