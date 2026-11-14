//
//  SectionHeader.swift
//  HobbyPlanet
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Typo.title(18))
                    .foregroundColor(Palette.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(Typo.caption)
                        .foregroundColor(Palette.inkTertiary)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(Typo.caption)
                    .foregroundColor(Palette.brand)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
