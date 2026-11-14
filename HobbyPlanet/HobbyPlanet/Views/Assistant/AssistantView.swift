//
//  AssistantView.swift
//  HobbyPlanet
//
//  AI 对话页。会话状态只存在内存里（退出即清空），
//  每次提问都把用户档案与近期活动作为上下文交给 AssistantService 组装。
//

import SwiftUI

struct AssistantView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var settingsStore: SettingsStore

    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var isThinking: Bool = false
    @State private var offlineHint: String?
    @FocusState private var inputFocused: Bool
    /// CI 截图用：进页面自动提一个问题
    var autoQuestion: String = ""

    private let quickPrompts = [
        "周末有什么活动推荐？",
        "怎么发起一个活动？",
        "我想找点不用花钱的乐子"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            introCard
                            ForEach(messages) { message in
                                bubble(message)
                                    .id(message.id)
                            }
                            if isThinking {
                                thinkingBubble.id("thinking")
                            }
                        }
                        .padding(.horizontal, Metric.pagePadding)
                        .padding(.vertical, 14)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: isThinking) { _ in
                        scrollToBottom(proxy)
                    }
                }

                quickPromptBar
                inputBar
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        messages.removeAll()
                        offlineHint = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .foregroundColor(Palette.inkSecondary)
                    .disabled(messages.isEmpty)
                }
            }
            .task {
                // 仅截图场景：自动提一个问题，拿到回答后再截图
                guard !autoQuestion.isEmpty, messages.isEmpty else { return }
                try? await Task.sleep(nanoseconds: 700_000_000)
                send(autoQuestion)
            }
        }
    }

    // MARK: - 顶部说明

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Palette.violet, Palette.brand],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("同好星球助手")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.ink)
                    Text(settingsStore.hasKey ? "已连接大模型" : "未配置密钥 · 本地回答")
                        .font(.system(size: 10.5))
                        .foregroundColor(settingsStore.hasKey ? Palette.mint : Palette.warning)
                }
                Spacer()
            }

            Text("我可以按你的兴趣挑活动、解释同好度怎么算，也能帮你把一句想法变成活动方案。")
                .font(.system(size: 12.5))
                .foregroundColor(Palette.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card(padding: 13)
    }

    // MARK: - 消息气泡

    private func bubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                AvatarView(symbol: "sparkles", size: 28, tint: Palette.violet)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .foregroundColor(message.role == .user ? .white : Palette.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(message.role == .user ? Palette.brand : Palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(message.role == .user ? Color.clear : Palette.line, lineWidth: 1)
                    )
                    .textSelection(.enabled)

                if let badge = message.source.badge {
                    Text(badge)
                        .font(.system(size: 9.5))
                        .foregroundColor(Palette.warning)
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }

    private var thinkingBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            AvatarView(symbol: "sparkles", size: 28, tint: Palette.violet)
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("正在想…")
                    .font(.system(size: 13))
                    .foregroundColor(Palette.inkTertiary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.surface)
            )
            Spacer(minLength: 40)
        }
    }

    // MARK: - 快捷问题

    private var quickPromptBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        send(prompt)
                    } label: {
                        Text(prompt)
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
            .padding(.horizontal, Metric.pagePadding)
            .padding(.vertical, 8)
        }
        .background(Palette.canvas)
    }

    // MARK: - 输入栏

    private var inputBar: some View {
        VStack(spacing: 6) {
            if let offlineHint {
                Text(offlineHint)
                    .font(.system(size: 10.5))
                    .foregroundColor(Palette.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Metric.pagePadding)
            }

            HStack(spacing: 10) {
                TextField("问点什么，比如「今晚去哪」", text: $input, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Palette.line, lineWidth: 1)
                    )

                Button {
                    send(input)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle().fill(canSend ? Palette.brand : Palette.inkTertiary.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(.horizontal, Metric.pagePadding)
            .padding(.bottom, 8)
        }
        .background(Palette.surface.opacity(0.96))
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    // MARK: - 行为

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }

        // history 只包含提问之前的消息，避免最后一句被重复拼进上下文
        let history = messages
        messages.append(.user(question))
        input = ""
        inputFocused = false
        isThinking = true
        offlineHint = nil
        Haptics.tap()

        let service = AssistantService(
            client: LLMClient(settings: settingsStore),
            profile: profileStore.profile,
            activities: store.activities
        )

        Task { @MainActor in
            let result = await service.answer(history: history, question: question)
            messages.append(.assistant(result.text, source: result.fromModel ? .model : .offline))
            isThinking = false
            if !result.fromModel {
                offlineHint = "这次是本地回答。在「我的 → 设置」里填好大模型密钥，可以获得更灵活的建议。"
                Haptics.warning()
            } else {
                Haptics.success()
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}
