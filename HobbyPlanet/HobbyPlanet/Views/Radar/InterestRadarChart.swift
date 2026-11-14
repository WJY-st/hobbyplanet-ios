//
//  InterestRadarChart.swift
//  HobbyPlanet
//
//  兴趣雷达图。用 Canvas 直接绘制：三层网格 + 六条轴线 + 数据多边形 + 分类文字。
//  相比引入图表库，自绘只有一百行，且能完全贴合 App 的配色。
//

import SwiftUI

struct InterestRadarChart: View {
    let values: [(category: HobbyCategory, value: Double)]
    var size: CGFloat = 250

    private var pointCount: Int { values.count }

    private func angle(at index: Int) -> Double {
        guard pointCount > 0 else { return 0 }
        return -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(pointCount)
    }

    private func point(center: CGPoint, radius: CGFloat, index: Int, scale: Double) -> CGPoint {
        let a = angle(at: index)
        return CGPoint(x: center.x + CGFloat(cos(a)) * radius * CGFloat(scale),
                       y: center.y + CGFloat(sin(a)) * radius * CGFloat(scale))
    }

    var body: some View {
        Canvas { context, canvasSize in
            guard pointCount >= 3 else { return }

            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2 - 34

            // 1. 同心网格
            for step in 1...3 {
                let scale = Double(step) / 3.0
                var ring = Path()
                for index in 0..<pointCount {
                    let p = point(center: center, radius: radius, index: index, scale: scale)
                    if index == 0 { ring.move(to: p) } else { ring.addLine(to: p) }
                }
                ring.closeSubpath()
                context.stroke(ring, with: .color(Palette.line), lineWidth: 1)
            }

            // 2. 轴线
            for index in 0..<pointCount {
                var axis = Path()
                axis.move(to: center)
                axis.addLine(to: point(center: center, radius: radius, index: index, scale: 1))
                context.stroke(axis, with: .color(Palette.line.opacity(0.9)), lineWidth: 1)
            }

            // 3. 数据多边形
            var polygon = Path()
            for (index, item) in values.enumerated() {
                let scale = max(0.06, min(1, item.value))
                let p = point(center: center, radius: radius, index: index, scale: scale)
                if index == 0 { polygon.move(to: p) } else { polygon.addLine(to: p) }
            }
            polygon.closeSubpath()

            context.fill(polygon, with: .linearGradient(
                Gradient(colors: [Palette.brand.opacity(0.42), Palette.violet.opacity(0.18)]),
                startPoint: CGPoint(x: center.x, y: center.y - radius),
                endPoint: CGPoint(x: center.x, y: center.y + radius)
            ))
            context.stroke(polygon, with: .color(Palette.brand), lineWidth: 2)

            // 4. 数据点
            for (index, item) in values.enumerated() {
                let scale = max(0.06, min(1, item.value))
                let p = point(center: center, radius: radius, index: index, scale: scale)
                let dot = Path(ellipseIn: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7))
                context.fill(dot, with: .color(Palette.brand))
                context.stroke(dot, with: .color(Palette.surface), lineWidth: 1.5)
            }

            // 5. 分类文字
            for (index, item) in values.enumerated() {
                let a = angle(at: index)
                let labelPoint = CGPoint(x: center.x + CGFloat(cos(a)) * (radius + 17),
                                         y: center.y + CGFloat(sin(a)) * (radius + 17))
                let text = Text(item.category.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Palette.inkSecondary)
                context.draw(text, at: labelPoint, anchor: .center)
            }
        }
        .frame(width: size, height: size)
    }
}
