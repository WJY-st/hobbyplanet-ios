//
//  OnboardingView.swift
//  HobbyPlanet
//
//  首次启动的引导：选兴趣 → 起昵称。两步走，避免一次性表单。
//  选中的兴趣直接决定后续“同好度”推荐的质量，所以这一步不做成可跳过。
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var step: Int = 0
    @State private var nickname: String = ""
    @State private var avatar: String = HobbyLibrary.avatarSymbols[0]

    private var canContinue: Bool {
        if step == 0 {
            return profileStore.profile.interests.count >= 3
        }
        return !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                Group {
                    if step == 0 {
                        interestStep
                    } else {
                        profileStep
                    }
                }
                .padding(.horizontal, Metric.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            footer
        }
        .background(Palette.canvas.ignoresSafeArea())
    }

    // MARK: - 头部

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Palette.brand, Palette.rose],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("同好星球")
                    .font(Typo.hero(24))
                    .foregroundColor(Palette.ink)
                Spacer()
                Text("\(step + 1) / 2")
                    .font(Typo.caption)
                    .foregroundColor(Palette.inkTertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(step == 0 ? "先告诉我你喜欢什么" : "给自己起个名字")
                    .font(Typo.hero(26))
                    .foregroundColor(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(step == 0
                     ? "至少选 3 个兴趣，推荐会按它来算同好度"
                     : "这个名字只存在本机，会出现在你发起的活动上")
                    .font(Typo.caption)
                    .foregroundColor(Palette.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, Metric.pagePadding)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - 第一步：兴趣

    private var interestStep: some View {
        VStack(spacing: 20) {
            ForEach(HobbyCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: category.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(category.tint)
                        Text(category.title)
                            .font(Typo.headline(14))
                            .foregroundColor(Palette.ink)
                        Text(category.slogan)
                            .font(.system(size: 11))
                            .foregroundColor(Palette.inkTertiary)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                        ForEach(HobbyLibrary.tags(for: category), id: \.self) { tag in
                            Button {
                                Haptics.select()
                                profileStore.toggleInterest(tag)
                            } label: {
                                TagChip(text: tag,
                                        tint: category.tint,
                                        selected: profileStore.isInterested(in: tag),
                                        showPlus: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Palette.surface)
                )
            }
        }
    }

    // MARK: - 第二步：昵称与头像

    private var profileStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                AvatarView(symbol: avatar, size: 90, tint: Palette.brand, borderWidth: 4)

                TextField("比如：小满", text: $nickname)
                    .font(.system(size: 17, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Palette.line, lineWidth: 1)
                    )
                    .submitLabel(.done)

                Text("最多 8 个字")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("挑一个头像")
                    .font(Typo.headline(14))
                    .foregroundColor(Palette.ink)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 12)], spacing: 12) {
                    ForEach(HobbyLibrary.avatarSymbols, id: \.self) { symbol in
                        Button {
                            Haptics.tap()
                            avatar = symbol
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(avatar == symbol ? Palette.brandSoft : Palette.surface)
                                Image(systemName: symbol)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(avatar == symbol ? Palette.brand : Palette.inkSecondary)
                            }
                            .frame(width: 52, height: 52)
                            .overlay(
                                Circle().stroke(avatar == symbol ? Palette.brand : Palette.line, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .card(padding: 0)
        }
    }

    // MARK: - 底部按钮

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                if step == 0 {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.28)) { step = 1 }
                } else {
                    Haptics.success()
                    profileStore.finishOnboarding(
                        nickname: nickname.trimmingCharacters(in: .whitespaces),
                        interests: profileStore.profile.interests,
                        avatar: avatar
                    )
                }
            } label: {
                Text(step == 0 ? "下一步" : "进入同好星球")
            }
            .buttonStyle(PrimaryButtonStyle(enabled: canContinue))
            .disabled(!canContinue)

            if step == 1 {
                Button("上一步") {
                    withAnimation(.easeInOut(duration: 0.28)) { step = 0 }
                }
                .font(Typo.caption)
                .foregroundColor(Palette.inkSecondary)
            }

            if step == 0 {
                Text("已选 \(profileStore.profile.interests.count) / 8（至少 3 个）")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.inkTertiary)
            }
        }
        .padding(.horizontal, Metric.pagePadding)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(Palette.canvas)
    }
}
