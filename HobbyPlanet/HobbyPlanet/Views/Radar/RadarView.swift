//
//  RadarView.swift
//  HobbyPlanet
//
//  同好雷达页。上半部分是你自己的兴趣画像（雷达图 + 标签），
//  下半部分是按同好度排序的活动。兴趣标签改动后，分数会立即重算。
//

import SwiftUI

struct RadarView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore

    private var distribution: [(category: HobbyCategory, value: Double)] {
        MatchEngine.distribution(of: profileStore.profile)
    }

    private var ranked: [MatchResult] {
        MatchEngine.ranked(store.upcoming, profile: profileStore.profile)
    }

    private var hasInterests: Bool {
        !profileStore.profile.interests.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileCard
                    tagSection
                    matchSection
                }
                .padding(.horizontal, Metric.pagePadding)
                .padding(.bottom, 28)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("同好雷达")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(value: AppRoute.interestEditor) {
                        Text("编辑兴趣")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Palette.brand)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .activity(let id):
                    ActivityDetailView(activityID: id)
                case .interestEditor:
                    InterestEditorView()
                case .myList(let filter):
                    MyActivitiesView(filter: filter)
                case .settings:
                    SettingsView()
                }
            }
        }
    }

    // MARK: - 画像卡

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("你的兴趣画像")
                        .font(Typo.title(17))
                        .foregroundColor(Palette.ink)
                    Text(hasInterests ? "六个方向里，你偏重 \(topCategoryText)" : "先去选几个兴趣标签吧")
                        .font(Typo.caption)
                        .foregroundColor(Palette.inkTertiary)
                }
                Spacer()
                Text("\(profileStore.profile.interestCount) 个标签")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Palette.brand)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Palette.brandSoft))
            }

            InterestRadarChart(values: distribution, size: 240)
                .frame(maxWidth: .infinity)

            if !hasInterests {
                NavigationLink(value: AppRoute.interestEditor) {
                    Text("去选标签")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    private var topCategoryText: String {
        let categories = profileStore.profile.topCategories
        guard !categories.isEmpty else { return "还没有明显偏好" }
        return categories.map { $0.title }.joined(separator: " / ")
    }

    // MARK: - 标签

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("我的兴趣标签")
                        .font(Typo.title(18))
                        .foregroundColor(Palette.ink)
                    Text("点一下可以取消")
                        .font(Typo.caption)
                        .foregroundColor(Palette.inkTertiary)
                }
                Spacer(minLength: 8)
                NavigationLink(value: AppRoute.interestEditor) {
                    HStack(spacing: 2) {
                        Text("管理")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(Typo.caption)
                    .foregroundColor(Palette.brand)
                }
            }

            if profileStore.profile.interests.isEmpty {
                Text("还没有选择，去「编辑兴趣」里挑几个。")
                    .font(Typo.caption)
                    .foregroundColor(Palette.inkTertiary)
                    .card(padding: 14)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                    ForEach(profileStore.profile.interests.sorted(), id: \.self) { tag in
                        Button {
                            Haptics.select()
                            profileStore.toggleInterest(tag)
                        } label: {
                            TagChip(text: tag, tint: Palette.brand, selected: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 匹配列表

    private var matchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "按同好度排给你", subtitle: "分数 = 兴趣重合 55 + 分类 15 + 时间 15 + 新鲜度 8 + 余位 7")

            if ranked.isEmpty {
                EmptyStateView(symbol: "dot.radiowaves.left.and.right",
                               title: "附近还没有活动",
                               message: "等有人发起，或者你自己来当第一个。")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(ranked) { result in
                        NavigationLink(value: AppRoute.activity(result.activity.id)) {
                            matchRow(result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func matchRow(_ result: MatchResult) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ScoreRing(score: result.score, size: 52, lineWidth: 5,
                      tint: result.activity.category.tint)

            VStack(alignment: .leading, spacing: 5) {
                Text(result.activity.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(result.activity.timeText) · \(result.activity.location)")
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.inkSecondary)
                    .lineLimit(1)

                Text(result.reasons.first ?? "换个领域试试")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.brand)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .card(padding: 12)
    }
}
