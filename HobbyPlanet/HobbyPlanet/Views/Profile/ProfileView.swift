//
//  ProfileView.swift
//  HobbyPlanet
//
//  「我的」页。上半部分是个人的三组数字，下半部分是入口列表。
//  数字全部由本地 Store 现算，不做冗余统计字段，避免数据不一致。
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: ActivityStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var showEditProfile: Bool = false

    private var joinedCount: Int {
        profileStore.profile.joinedIDs.filter { store.activity(with: $0) != nil }.count
    }

    private var hostedCount: Int {
        store.activities.filter { $0.isMine }.count
    }

    private var favoriteCount: Int {
        profileStore.profile.favoriteIDs.filter { store.activity(with: $0) != nil }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    statsRow
                    menuCard
                    aboutFooter
                }
                .padding(.horizontal, Metric.pagePadding)
                .padding(.bottom, 28)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
            }
        }
    }

    // MARK: - 头部

    private var headerCard: some View {
        HStack(spacing: 14) {
            AvatarView(symbol: profileStore.profile.avatarSymbol, size: 64, tint: Palette.brand, borderWidth: 3)

            VStack(alignment: .leading, spacing: 5) {
                Text(profileStore.profile.displayName)
                    .font(Typo.hero(22))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)

                Text(profileStore.profile.interests.isEmpty
                     ? "还没选兴趣标签"
                     : "\(profileStore.profile.interestCount) 个兴趣 · \(profileStore.profile.topCategories.map { $0.title }.joined(separator: " / "))")
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.tap()
                showEditProfile = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.brand)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Palette.brandSoft))
            }
            .buttonStyle(.plain)
        }
        .card(padding: 16)
    }

    // MARK: - 数字

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: joinedCount, title: "已报名", tint: Palette.brand)
            statTile(value: hostedCount, title: "我发起的", tint: Palette.violet)
            statTile(value: favoriteCount, title: "收藏", tint: Palette.rose)
        }
    }

    private func statTile(value: Int, title: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(tint)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    // MARK: - 菜单

    private var menuCard: some View {
        VStack(spacing: 0) {
            menuRow(icon: "calendar.badge.checkmark",
                    tint: Palette.brand,
                    title: "我报名的活动",
                    subtitle: "\(joinedCount) 场",
                    route: .myList(.joined))

            divider

            menuRow(icon: "megaphone.fill",
                    tint: Palette.violet,
                    title: "我发起的活动",
                    subtitle: "\(hostedCount) 场",
                    route: .myList(.hosted))

            divider

            menuRow(icon: "heart.fill",
                    tint: Palette.rose,
                    title: "我的收藏",
                    subtitle: "\(favoriteCount) 场",
                    route: .myList(.favorite))

            divider

            menuRow(icon: "tag.fill",
                    tint: Palette.mint,
                    title: "兴趣标签",
                    subtitle: "\(profileStore.profile.interestCount) 个",
                    route: .interestEditor)

            divider

            menuRow(icon: "gearshape.fill",
                    tint: Palette.inkSecondary,
                    title: "设置",
                    subtitle: "接口与外观",
                    route: .settings)
        }
        .background(
            RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metric.cardRadius, style: .continuous)
                .stroke(Palette.line, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(height: 1)
            .padding(.leading, 54)
    }

    private func menuRow(icon: String, tint: Color, title: String, subtitle: String, route: AppRoute) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(tint.opacity(0.12)))

                Text(title)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundColor(Palette.ink)

                Spacer()

                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.inkTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Palette.inkTertiary.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 页脚

    private var aboutFooter: some View {
        VStack(spacing: 4) {
            Text("同好星球 1.0.0")
                .font(.system(size: 10.5))
                .foregroundColor(Palette.inkTertiary)
            Text("移动开发技术与应用 · 课程设计作品")
                .font(.system(size: 10.5))
                .foregroundColor(Palette.inkTertiary.opacity(0.8))
        }
        .padding(.top, 6)
    }
}

// MARK: - 编辑资料

struct EditProfileSheet: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var avatar: String = "sparkles"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AvatarView(symbol: avatar, size: 86, tint: Palette.brand, borderWidth: 4)

                    TextField("昵称", text: $nickname)
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Palette.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Palette.line, lineWidth: 1)
                        )
                        .onChange(of: nickname) { newValue in
                            if newValue.count > 8 {
                                nickname = String(newValue.prefix(8))
                            }
                        }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 12)], spacing: 12) {
                        ForEach(HobbyLibrary.avatarSymbols, id: \.self) { symbol in
                            Button {
                                Haptics.tap()
                                avatar = symbol
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(avatar == symbol ? Palette.brandSoft : Palette.surface)
                                    Image(systemName: symbol)
                                        .font(.system(size: 19, weight: .semibold))
                                        .foregroundColor(avatar == symbol ? Palette.brand : Palette.inkSecondary)
                                }
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle().stroke(avatar == symbol ? Palette.brand : Palette.line, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Metric.pagePadding)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Palette.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            profileStore.profile.nickname = trimmed
                        }
                        profileStore.profile.avatarSymbol = avatar
                        Haptics.success()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.brand)
                }
            }
            .onAppear {
                nickname = profileStore.profile.nickname
                avatar = profileStore.profile.avatarSymbol
            }
        }
    }
}
