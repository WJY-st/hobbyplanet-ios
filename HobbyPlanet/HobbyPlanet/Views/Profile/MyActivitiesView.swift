//
//  MyActivitiesView.swift
//  HobbyPlanet
//
//  三个列表共用同一个视图：我报名的 / 我发起的 / 我的收藏。
//  用 AppRoute.MyListFilter 区分数据来源，避免复制三份几乎相同的列表代码。
//

import SwiftUI

struct MyActivitiesView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore

    let filter: AppRoute.MyListFilter

    @State private var pendingDelete: HobbyActivity?

    private var items: [HobbyActivity] {
        switch filter {
        case .joined:
            return store.activities
                .filter { profileStore.profile.joinedIDs.contains($0.id) }
                .sorted { $0.startAt < $1.startAt }
        case .hosted:
            return store.activities
                .filter { $0.isMine }
                .sorted { $0.createdAt > $1.createdAt }
        case .favorite:
            return store.activities
                .filter { profileStore.profile.favoriteIDs.contains($0.id) }
                .sorted { $0.startAt < $1.startAt }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .joined: return "还没有报名任何活动"
        case .hosted: return "还没有发起过活动"
        case .favorite: return "收藏夹是空的"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .joined: return "去「发现」看看，报名之后会出现在这里，开始前记得留出时间。"
        case .hosted: return "点首页右上角的加号，用 AI 起草一个活动，两分钟就能发出去。"
        case .favorite: return "看到感兴趣但时间冲突的活动，先收藏起来，之后再来看看。"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if items.isEmpty {
                    EmptyStateView(symbol: "tray",
                                   title: emptyTitle,
                                   message: emptyMessage)
                } else {
                    ForEach(items) { activity in
                        NavigationLink(value: AppRoute.activity(activity.id)) {
                            row(activity)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if activity.isMine {
                                Button(role: .destructive) {
                                    pendingDelete = activity
                                } label: {
                                    Label("删除活动", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Metric.pagePadding)
            .padding(.vertical, 14)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .navigationTitle(filter.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("删除后不可恢复，确定吗？",
                            isPresented: Binding(
                                get: { pendingDelete != nil },
                                set: { if !$0 { pendingDelete = nil } }
                            ),
                            titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let activity = pendingDelete {
                    store.delete(id: activity.id)
                    profileStore.unmarkJoined(activity.id)
                    profileStore.profile.favoriteIDs.remove(activity.id)
                    Haptics.warning()
                }
                pendingDelete = nil
            }
            Button("取消", role: .cancel) { pendingDelete = nil }
        }
    }

    private func row(_ activity: HobbyActivity) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(activity.category.tint.opacity(0.14))
                Image(systemName: activity.coverSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(activity.category.tint)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 5) {
                Text(activity.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(activity.timeText) · \(activity.location)")
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.inkSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    MiniTag(text: activity.isFinished ? "已结束" : activity.seatText,
                            tint: activity.isFinished ? Palette.inkTertiary : Palette.mint)
                    if activity.isMine {
                        MiniTag(text: "我发起的", tint: Palette.violet)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .card(padding: 12)
    }
}
