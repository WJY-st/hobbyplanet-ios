//
//  InterestEditorView.swift
//  HobbyPlanet
//
//  兴趣标签的集中编辑页。改动即刻生效（写回 ProfileStore），
//  没有“保存”按钮，减少一次点击。
//

import SwiftUI

struct InterestEditorView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    private var selectedCount: Int {
        profileStore.profile.interests.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                ForEach(HobbyCategory.allCases) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: category.symbol)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(category.tint)
                            Text(category.title)
                                .font(Typo.headline(14))
                                .foregroundColor(Palette.ink)
                            Spacer()
                            Text("\(hitCount(for: category)) 个")
                                .font(.system(size: 10.5))
                                .foregroundColor(Palette.inkTertiary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                            ForEach(HobbyLibrary.tags(for: category), id: \.self) { tag in
                                Button {
                                    Haptics.select()
                                    if !profileStore.isInterested(in: tag) && selectedCount >= 8 {
                                        Haptics.warning()
                                        return
                                    }
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
            .padding(.horizontal, Metric.pagePadding)
            .padding(.vertical, 14)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .navigationTitle("兴趣标签")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("已选 \(selectedCount) / 8")
                .font(Typo.headline(15))
                .foregroundColor(Palette.ink)
            Text("标签越贴近你真实的生活，同好度算得越准。选 3 到 8 个就够。")
                .font(.system(size: 11.5))
                .foregroundColor(Palette.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: Double(selectedCount), total: 8)
                .tint(Palette.brand)
                .padding(.top, 4)
        }
    }

    private func hitCount(for category: HobbyCategory) -> Int {
        let library = Set(HobbyLibrary.tags(for: category))
        return profileStore.profile.interests.filter { library.contains($0) }.count
    }
}
