//
//  AIPlanSheet.swift
//  HobbyPlanet
//
//  AI 策划面板。用户写一句想法 → 调用大模型 → 展示结构化草案 → 一键回填表单。
//  失败时不会弹“错误”，而是展示本地模板生成的草案，并用一行小字说明来源，
//  保证这个入口在任何网络状态下都能走完。
//

import SwiftUI

struct AIPlanSheet: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @Binding var category: HobbyCategory
    /// CI 截图用：预填一句想法并自动生成
    var prefillIdea: String = ""
    var onApply: (AIPlanDraft) -> Void

    @State private var idea: String = ""
    @State private var isLoading: Bool = false
    @State private var draft: AIPlanDraft?
    @State private var note: String?
    @State private var usedModel: Bool = false

    private let examples = [
        "周五晚上想在操场跑个五公里，配速慢一点",
        "找几个人去撸猫，顺便拍点照片",
        "想在做完作业后去学校附近吃点好的",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    promptSection
                    categorySection
                    actionSection

                    if isLoading {
                        loadingView
                    } else if let draft {
                        draftCard(draft)
                    }
                }
                .padding(.horizontal, Metric.pagePadding)
                .padding(.vertical, 16)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("AI 策划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(Palette.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用到表单") {
                        if let draft {
                            onApply(draft)
                            dismiss()
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(draft == nil ? Palette.inkTertiary : Palette.brand)
                    .disabled(draft == nil)
                }
            }
            .task {
                // 仅截图场景：预填想法后自动生成一次（无密钥时走本地模板，仍会出完整草案）
                guard draft == nil, !prefillIdea.isEmpty else { return }
                idea = prefillIdea
                try? await Task.sleep(nanoseconds: 500_000_000)
                generate()
            }
        }
    }

    // MARK: - 输入

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("用一句话说说你想做什么")
                .font(Typo.headline(15))
                .foregroundColor(Palette.ink)

            ZStack(alignment: .topLeading) {
                if idea.isEmpty {
                    Text("比如：周六下午想找人一起做陶艺，预算不多")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.inkTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $idea)
                    .font(.system(size: 14))
                    .frame(minHeight: 84, maxHeight: 120)
                    .padding(8)
                    .onChange(of: idea) { newValue in
                        if newValue.count > 120 {
                            idea = String(newValue.prefix(120))
                        }
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Palette.line, lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(examples, id: \.self) { example in
                        Button {
                            Haptics.select()
                            idea = example
                        } label: {
                            Text(example)
                                .font(.system(size: 11.5))
                                .foregroundColor(Palette.inkSecondary)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Palette.surface))
                                .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("归到哪个分类")
                .font(Typo.headline(14))
                .foregroundColor(Palette.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(HobbyCategory.allCases) { item in
                    Button {
                        Haptics.select()
                        category = item
                    } label: {
                        Text(item.title)
                            .font(Typo.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundColor(category == item ? .white : item.tint)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(category == item ? item.tint : item.tint.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionSection: some View {
        Button {
            generate()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text(isLoading ? "正在想…" : "生成方案")
            }
        }
        .buttonStyle(PrimaryButtonStyle(enabled: !idea.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading))
        .disabled(idea.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("正在把这句话整理成活动方案…")
                .font(Typo.caption)
                .foregroundColor(Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 16)
    }

    // MARK: - 结果

    private func draftCard(_ draft: AIPlanDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: usedModel ? "sparkles" : "bolt.horizontal.circle")
                    .font(.system(size: 11, weight: .bold))
                Text(usedModel ? "由大模型生成" : "本地模板生成")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(usedModel ? Palette.violet : Palette.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill((usedModel ? Palette.violet : Palette.amber).opacity(0.12))
            )

            Text(draft.title)
                .font(Typo.title(18))
                .foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(draft.summary)
                .font(.system(size: 13.5))
                .foregroundColor(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let note {
                Text(note)
                    .font(.system(size: 11))
                    .foregroundColor(Palette.warning)
            }

            Divider().background(Palette.line)

            VStack(alignment: .leading, spacing: 8) {
                Text("流程")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Palette.inkTertiary)
                ForEach(Array(draft.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Palette.brand))
                        Text(step)
                            .font(.system(size: 13))
                            .foregroundColor(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !draft.materials.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("物料")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Palette.inkTertiary)
                    HStack(spacing: 6) {
                        ForEach(draft.materials, id: \.self) { item in
                            MiniTag(text: item, tint: Palette.amber)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                MiniTag(text: "\(draft.durationMinutes) 分钟", tint: Palette.sky)
                MiniTag(text: "\(draft.capacity) 人", tint: Palette.mint)
                ForEach(draft.tags, id: \.self) { tag in
                    MiniTag(text: tag, tint: category.tint)
                }
            }
        }
        .card(padding: 16)
    }

    // MARK: - 生成

    private func generate() {
        let text = idea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        isLoading = true
        note = nil
        Haptics.tap()

        let planner = AIPlanner(client: LLMClient(settings: settingsStore))
        let profile = profileStore.profile
        let chosenCategory = category

        Task { @MainActor in
            let result = await planner.generate(prompt: text,
                                                category: chosenCategory,
                                                profile: profile)
            draft = result.draft
            usedModel = result.fromModel
            note = result.note
            isLoading = false
            Haptics.success()
        }
    }
}
