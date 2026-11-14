//
//  DiscoverView.swift
//  HobbyPlanet
//
//  首页。自上而下：问候 → 搜索 → 分类筛选 → 为你推荐（横向） → 全部活动（纵向列表）。
//  筛选与搜索都在本地数组上做，数据量是几十条，不需要索引。
//

import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var searchText: String = ""
    @State private var selectedCategory: HobbyCategory?
    @State private var showPublish: Bool = false

    // MARK: - 数据

    private var keyword: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredActivities: [HobbyActivity] {
        var items = store.upcoming

        if let selectedCategory {
            items = items.filter { $0.category == selectedCategory }
        }

        if !keyword.isEmpty {
            items = items.filter { activity in
                activity.title.contains(keyword)
                    || activity.summary.contains(keyword)
                    || activity.location.contains(keyword)
                    || activity.hostName.contains(keyword)
                    || activity.tags.contains { $0.contains(keyword) }
            }
        }
        return items
    }

    private var rankedResults: [MatchResult] {
        MatchEngine.ranked(filteredActivities, profile: profileStore.profile)
    }

    private var recommendations: [MatchResult] {
        guard !profileStore.profile.interests.isEmpty else { return [] }
        return Array(rankedResults.prefix(4))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "早上好"
        case 11..<14: return "中午好"
        case 14..<18: return "下午好"
        default: return "晚上好"
        }
    }

    // MARK: - 视图

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchBar
                    categoryRow
                    aiBanner

                    if !recommendations.isEmpty {
                        recommendationSection
                    }

                    allSection
                }
                .padding(.horizontal, Metric.pagePadding)
                .padding(.bottom, 28)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .activity(let id):
                    ActivityDetailView(activityID: id)
                case .myList(let filter):
                    MyActivitiesView(filter: filter)
                case .settings:
                    SettingsView()
                case .interestEditor:
                    InterestEditorView()
                }
            }
            .sheet(isPresented: $showPublish) {
                PublishView()
            }
        }
    }

    // MARK: 头部

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(greeting)，\(profileStore.profile.displayName)")
                    .font(Typo.hero(23))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text("校园三公里 · \(store.upcoming.count) 场活动进行中")
                        .font(Typo.caption)
                        .foregroundColor(Palette.inkTertiary)
                }
            }
            Spacer(minLength: 8)

            Button {
                Haptics.tap()
                showPublish = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Palette.brand)
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Palette.brand.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: 搜索框

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Palette.inkTertiary)

            TextField("搜活动、地点或兴趣，比如「陶艺」", text: $searchText)
                .font(.system(size: 14))
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    // MARK: 分类

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    Haptics.select()
                    selectedCategory = nil
                } label: {
                    Text("全部")
                        .font(Typo.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedCategory == nil ? .white : Palette.inkSecondary)
                        .background(
                            Capsule().fill(selectedCategory == nil ? Palette.ink : Palette.surface)
                        )
                        .overlay(
                            Capsule().stroke(selectedCategory == nil ? Color.clear : Palette.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                ForEach(HobbyCategory.allCases) { category in
                    Button {
                        Haptics.select()
                        selectedCategory = (selectedCategory == category) ? nil : category
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.symbol)
                                .font(.system(size: 10, weight: .semibold))
                            Text(category.title)
                                .font(Typo.caption)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedCategory == category ? .white : category.tint)
                        .background(
                            Capsule().fill(selectedCategory == category ? category.tint : Palette.surface)
                        )
                        .overlay(
                            Capsule().stroke(selectedCategory == category ? Color.clear : Palette.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: AI 入口条

    private var aiBanner: some View {
        Button {
            Haptics.tap()
            showPublish = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.violet, Palette.brand],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("不知道玩什么？让 AI 帮你想")
                        .font(Typo.headline(14))
                        .foregroundColor(Palette.ink)
                    Text("一句话描述想法，自动生成完整活动方案")
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.inkTertiary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Palette.inkTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Palette.brandSoft.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: 推荐

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "为你推荐",
                          subtitle: "按兴趣标签与时间偏好算出的同好度")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations) { result in
                        NavigationLink(value: AppRoute.activity(result.activity.id)) {
                            FeaturedCard(activity: result.activity, score: result.score)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: 全部活动

    private var allSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: selectedCategory.map { "\($0.title)活动" } ?? "全部活动",
                          subtitle: "共 \(filteredActivities.count) 场")

            if filteredActivities.isEmpty {
                EmptyStateView(
                    symbol: "telescope",
                    title: keyword.isEmpty ? "这个分类还没有活动" : "没有搜到相关活动",
                    message: keyword.isEmpty
                        ? "不如你来当第一个发起人，点右上角的加号试试。"
                        : "换个关键词，或者去别的分类看看。",
                    actionTitle: "发起一场",
                    action: { showPublish = true }
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(rankedResults) { result in
                        NavigationLink(value: AppRoute.activity(result.activity.id)) {
                            ActivityRow(activity: result.activity, score: result.score)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
