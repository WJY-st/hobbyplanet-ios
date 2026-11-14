//
//  PublishView.swift
//  HobbyPlanet
//
//  发起活动。整页是一张可滚动的表单，顶部留了一个「AI 起草」入口：
//  生成结果通过闭包回填到表单，用户可以继续改，也可以整页清空重来。
//

import SwiftUI

struct PublishView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var category: HobbyCategory = .handcraft
    @State private var selectedTags: Set<String> = []
    @State private var startAt: Date = Date().addingTimeInterval(86_400)
    @State private var durationMinutes: Int = 120
    @State private var location: String = ""
    @State private var capacity: Int = 12
    @State private var steps: [String] = []
    @State private var materials: [String] = []

    @State private var showAIPlan: Bool = false
    @State private var showValidation: Bool = false
    @State private var validationMessage: String = ""

    // MARK: - 校验

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedSummary: String { summary.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedLocation: String { location.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canPublish: Bool {
        trimmedTitle.count >= 4
            && trimmedSummary.count >= 10
            && !trimmedLocation.isEmpty
            && !selectedTags.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    aiEntry
                    basicSection
                    categorySection
                    tagSection
                    timeSection
                    detailSection
                }
                .padding(.horizontal, Metric.pagePadding)
                .padding(.vertical, 16)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("发起活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Palette.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") { publish() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canPublish ? Palette.brand : Palette.inkTertiary)
                }
            }
            .sheet(isPresented: $showAIPlan) {
                AIPlanSheet(category: $category) { draft in
                    apply(draft)
                }
            }
            .alert("还差一点", isPresented: $showValidation) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - AI 入口

    private var aiEntry: some View {
        Button {
            Haptics.tap()
            showAIPlan = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Palette.violet, Palette.brand],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 42, height: 42)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("让 AI 起草活动方案")
                        .font(Typo.headline(14))
                        .foregroundColor(Palette.ink)
                    Text("一句话描述，标题、流程、物料自动填好")
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.inkTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Palette.inkTertiary)
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Palette.brandSoft.opacity(0.65))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 基本信息

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "基本信息", subtitle: "标题短一点，别人更容易点进来")

            VStack(alignment: .leading, spacing: 12) {
                TextField("活动标题，比如「周五夜跑五公里」", text: $title)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(fieldBackground)
                    .onChange(of: title) { newValue in
                        if newValue.count > 30 {
                            title = String(newValue.prefix(30))
                        }
                    }

                ZStack(alignment: .topLeading) {
                    if summary.isEmpty {
                        Text("说说做什么、怎么玩、适合谁来")
                            .font(.system(size: 14))
                            .foregroundColor(Palette.inkTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }

                    TextEditor(text: $summary)
                        .font(.system(size: 14))
                        .frame(minHeight: 96, maxHeight: 140)
                        .padding(8)
                        .background(Color.clear)
                        .onChange(of: summary) { newValue in
                            if newValue.count > 140 {
                                summary = String(newValue.prefix(140))
                            }
                        }
                }
                .background(fieldBackground)

                HStack {
                    Text("\(trimmedSummary.count) / 140")
                        .font(.system(size: 10.5))
                        .foregroundColor(Palette.inkTertiary)
                    Spacer()
                }
            }
            .card(padding: 14)
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Palette.canvas)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Palette.line, lineWidth: 1)
            )
    }

    // MARK: - 分类

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "活动分类")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                ForEach(HobbyCategory.allCases) { item in
                    Button {
                        Haptics.select()
                        category = item
                        selectedTags = selectedTags.filter { HobbyLibrary.tags(for: item).contains($0) }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 11, weight: .semibold))
                            Text(item.title)
                                .font(Typo.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundColor(category == item ? .white : item.tint)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(category == item ? item.tint : item.tint.opacity(0.10))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 标签

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "兴趣标签", subtitle: "最多 5 个，决定别人能不能搜到你")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                ForEach(HobbyLibrary.tags(for: category), id: \.self) { tag in
                    Button {
                        Haptics.select()
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else if selectedTags.count < 5 {
                            selectedTags.insert(tag)
                        }
                    } label: {
                        TagChip(text: tag,
                                tint: category.tint,
                                selected: selectedTags.contains(tag),
                                showPlus: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 时间与地点

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "时间与地点")

            VStack(spacing: 14) {
                DatePicker("开始时间", selection: $startAt, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .font(.system(size: 14))
                    .tint(Palette.brand)

                Divider().background(Palette.line)

                HStack {
                    Text("预计时长")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Text(Fmt.duration(minutes: durationMinutes))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.brand)
                    Stepper("", value: $durationMinutes, in: 30...240, step: 30)
                        .labelsHidden()
                }

                Divider().background(Palette.line)

                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                        .foregroundColor(Palette.brand)
                    TextField("集合地点，比如「东区草坪」", text: $location)
                        .font(.system(size: 14))
                }

                Divider().background(Palette.line)

                HStack {
                    Text("人数上限")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Text("\(capacity) 人")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.brand)
                    Stepper("", value: $capacity, in: 4...50, step: 1)
                        .labelsHidden()
                }
            }
            .card(padding: 16)
        }
    }

    // MARK: - 流程与物料

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "流程与物料", subtitle: "用 AI 起草时会自动填好，也可以自己改")

            VStack(alignment: .leading, spacing: 10) {
                if steps.isEmpty {
                    Text("还没有流程，点上面的「让 AI 起草」试试。")
                        .font(Typo.caption)
                        .foregroundColor(Palette.inkTertiary)
                } else {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Palette.brand))
                            Text(step)
                                .font(.system(size: 13))
                                .foregroundColor(Palette.ink)
                            Spacer(minLength: 0)
                            Button {
                                steps.remove(at: index)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Palette.inkTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !materials.isEmpty {
                    Divider().background(Palette.line)
                    HStack(spacing: 6) {
                        ForEach(materials, id: \.self) { item in
                            MiniTag(text: item, tint: Palette.amber)
                        }
                    }
                }
            }
            .card(padding: 14)
        }
    }

    // MARK: - 行为

    private func apply(_ draft: AIPlanDraft) {
        title = draft.title
        summary = draft.summary
        steps = draft.steps
        materials = draft.materials
        durationMinutes = draft.durationMinutes
        capacity = draft.capacity
        selectedTags = Set(draft.tags.filter { HobbyLibrary.tags(for: category).contains($0) })
        Haptics.success()
    }

    private func publish() {
        guard canPublish else {
            validationMessage = "标题至少 4 个字，简介至少 10 个字，还要选好标签和地点。"
            showValidation = true
            return
        }

        let activity = HobbyActivity(
            title: trimmedTitle,
            summary: trimmedSummary,
            category: category,
            tags: Array(selectedTags).sorted(),
            startAt: startAt,
            durationMinutes: durationMinutes,
            location: trimmedLocation,
            capacity: capacity,
            hostName: profileStore.profile.displayName,
            coverSymbol: category.symbol,
            steps: steps,
            materials: materials,
            participants: [
                Participant(name: profileStore.profile.displayName,
                            symbol: profileStore.profile.avatarSymbol)
            ],
            isMine: true
        )

        store.add(activity)
        profileStore.markJoined(activity.id)
        Haptics.success()
        dismiss()
    }
}
