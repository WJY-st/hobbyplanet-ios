//
//  SettingsView.swift
//  HobbyPlanet
//
//  设置页：大模型接口、外观、本地数据。
//  密钥输入框默认隐藏内容，保存后只回显掩码；「测试连接」会用一条最小请求验证配置是否可用。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var activityStore: ActivityStore

    @State private var keyInput: String = ""
    @State private var revealKey: Bool = false
    @State private var testState: TestState = .idle
    @State private var showResetConfirm: Bool = false
    @State private var showKeySaved: Bool = false

    enum TestState: Equatable {
        case idle
        case running
        case success(String)
        case failure(String)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                apiSection
                appearanceSection
                dataSection
                aboutSection
            }
            .padding(.horizontal, Metric.pagePadding)
            .padding(.vertical, 16)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("已保存", isPresented: $showKeySaved) {
            Button("好", role: .cancel) {}
        } message: {
            Text("密钥已写入系统钥匙串，不会出现在任何明文配置里。")
        }
        .confirmationDialog("会清空本机所有活动与个人档案，确定吗？",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("清空并恢复示例数据", role: .destructive) {
                activityStore.resetToSeed()
                profileStore.resetProfile()
                Haptics.warning()
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - 接口

    private var apiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "大模型接口", subtitle: "兼容 OpenAI Chat Completions 协议的任意服务")

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settingsStore.hasKey ? "已配置密钥" : "未配置密钥")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(settingsStore.hasKey ? Palette.success : Palette.warning)
                        Text(settingsStore.maskedKey)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Palette.inkTertiary)
                    }
                    Spacer()
                    Circle()
                        .fill(settingsStore.hasKey ? Palette.success : Palette.inkTertiary.opacity(0.45))
                        .frame(width: 8, height: 8)
                }

                HStack(spacing: 8) {
                    Group {
                        if revealKey {
                            TextField("sk-...", text: $keyInput)
                        } else {
                            SecureField("sk-...", text: $keyInput)
                        }
                    }
                    .font(.system(size: 13, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(11)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Palette.canvas)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Palette.line, lineWidth: 1)
                    )

                    Button {
                        revealKey.toggle()
                    } label: {
                        Image(systemName: revealKey ? "eye.slash" : "eye")
                            .font(.system(size: 13))
                            .foregroundColor(Palette.inkSecondary)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Palette.canvas)
                            )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Button {
                        settingsStore.updateKey(keyInput)
                        keyInput = ""
                        if settingsStore.hasKey {
                            Haptics.success()
                            showKeySaved = true
                        }
                    } label: {
                        Text("保存密钥")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        settingsStore.updateKey("")
                        keyInput = ""
                        Haptics.warning()
                    } label: {
                        Text("清除")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Palette.danger)
                    .frame(width: 68, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Palette.danger.opacity(0.10))
                    )
                    .buttonStyle(.plain)
                    .disabled(!settingsStore.hasKey)
                }

                Divider().background(Palette.line)

                fieldBlock(title: "接口地址",
                           placeholder: SettingsStore.defaultBaseURL,
                           text: Binding(get: { settingsStore.baseURL },
                                         set: { settingsStore.baseURL = $0 }))

                fieldBlock(title: "模型名称",
                           placeholder: SettingsStore.defaultModel,
                           text: Binding(get: { settingsStore.model },
                                         set: { settingsStore.model = $0 }))

                Button {
                    testConnection()
                } label: {
                    HStack(spacing: 8) {
                        if testState == .running {
                            ProgressView().scaleEffect(0.8)
                        }
                        Text(testState == .running ? "正在测试…" : "测试连接")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(enabled: settingsStore.hasKey && testState != .running))
                .disabled(!settingsStore.hasKey || testState == .running)

                testResultView
            }
            .card(padding: 14)
        }
    }

    private func fieldBlock(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11.5))
                .foregroundColor(Palette.inkTertiary)
            TextField(placeholder, text: text)
                .font(.system(size: 12.5, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(11)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Palette.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var testResultView: some View {
        switch testState {
        case .idle:
            EmptyView()
        case .running:
            EmptyView()
        case .success(let message):
            resultBanner(text: message, tint: Palette.success, icon: "checkmark.circle.fill")
        case .failure(let message):
            resultBanner(text: message, tint: Palette.danger, icon: "exclamationmark.triangle.fill")
        }
    }

    private func resultBanner(text: String, tint: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(tint)
            Text(text)
                .font(.system(size: 11.5))
                .foregroundColor(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.10))
        )
    }

    // MARK: - 外观

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "外观")

            VStack(alignment: .leading, spacing: 10) {
                Picker("外观", selection: Binding(get: { settingsStore.appearance },
                                                  set: { settingsStore.appearance = $0 })) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("深浅色都使用同一套语义色，切换后不影响可读性。")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.inkTertiary)
            }
            .card(padding: 14)
        }
    }

    // MARK: - 数据

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "本地数据")

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("活动数据")
                        .font(.system(size: 13.5))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Text("\(activityStore.activities.count) 条")
                        .font(.system(size: 12))
                        .foregroundColor(Palette.inkTertiary)
                }

                HStack {
                    Text("当前昵称")
                        .font(.system(size: 13.5))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Text(profileStore.profile.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(Palette.inkTertiary)
                }

                Divider().background(Palette.line)

                Button {
                    showResetConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("清空本地数据")
                    }
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(Palette.danger)
                }
                .buttonStyle(.plain)

                if let error = activityStore.lastErrorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(Palette.warning)
                }
            }
            .card(padding: 14)
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "关于")

            VStack(alignment: .leading, spacing: 8) {
                aboutRow("版本", "1.0.0 (26)")
                aboutRow("技术栈", "SwiftUI · async/await · URLSession")
                aboutRow("数据存放", "本机 Application Support + 钥匙串")
                aboutRow("隐私", "不上传任何个人数据，仅把提问与兴趣标签发送给所配置的大模型服务")
            }
            .card(padding: 14)
        }
    }

    private func aboutRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundColor(Palette.inkTertiary)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.system(size: 12.5))
                .foregroundColor(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 测试连接

    private func testConnection() {
        testState = .running
        let client = LLMClient(settings: settingsStore)
        let model = settingsStore.model

        Task { @MainActor in
            do {
                let reply = try await client.chat(
                    messages: [.system("你是一个连通性测试助手，只需回复 OK。"),
                               .user("ping")],
                    temperature: 0,
                    maxTokens: 16
                )
                testState = .success("连接成功，模型 \(model) 返回：\(reply.prefix(40))")
            } catch {
                let message = (error as? LLMError)?.errorDescription ?? error.localizedDescription
                testState = .failure(message)
            }
        }
    }
}
