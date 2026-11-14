//
//  ScoreRing.swift
//  HobbyPlanet
//
//  同好度圆环。用 Circle().trim 画进度，比自绘 Path 更省事，
//  但需要显式指定 rotationEffect(-90°) 让起点回到 12 点方向。
//

import SwiftUI

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 54
    var lineWidth: CGFloat = 6
    var tint: Color = Palette.brand

    private var progress: Double {
        min(1, max(0, Double(score) / 100))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.6), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)

            VStack(spacing: -2) {
                Text("\(score)")
                    .font(.system(size: size * 0.30, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.ink)
                Text("同好")
                    .font(.system(size: size * 0.16, weight: .medium))
                    .foregroundColor(Palette.inkTertiary)
            }
        }
        .frame(width: size, height: size)
    }
}
