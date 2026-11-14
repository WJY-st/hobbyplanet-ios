//
//  Formatters.swift
//  HobbyPlanet
//
//  日期文案统一收口。界面里出现的“今天 19:00”“3 天后”等相对时间都在这里生成，
//  避免各个视图各写一套 DateFormatter 造成格式不一致。
//

import Foundation

enum Fmt {
    private static func make(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter
    }

    static let hourMinute = make("HH:mm")
    static let monthDay = make("M月d日")
    static let monthDayTime = make("M月d日 HH:mm")
    static let weekday = make("EEE")
    static let fullDay = make("yyyy年M月d日")

    /// “今天 19:00”“明天 14:30”“周六 10:00”“11月20日 19:00”
    static func activityTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let clock = hourMinute.string(from: date)

        if calendar.isDateInToday(date) {
            return "今天 \(clock)"
        }
        if calendar.isDateInTomorrow(date) {
            return "明天 \(clock)"
        }
        if calendar.isDateInYesterday(date) {
            return "昨天 \(clock)"
        }

        let interval = date.timeIntervalSinceNow
        if interval > 0 && interval < 6 * 24 * 3600 {
            return "\(weekday.string(from: date)) \(clock)"
        }
        return monthDayTime.string(from: date)
    }

    /// 倒计时文案：用于详情页的“还有 3 天开始”
    static func countdown(to date: Date) -> String {
        let seconds = date.timeIntervalSince(Date())
        if seconds <= 0 {
            return "已开始"
        }
        let hours = Int(seconds / 3600)
        if hours < 1 {
            return "\(Int(seconds / 60)) 分钟后开始"
        }
        if hours < 24 {
            return "\(hours) 小时后开始"
        }
        return "\(hours / 24) 天后开始"
    }

    /// 相对发布时间：刚刚 / 5 分钟前 / 3 小时前 / 2 天前
    static func relative(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "刚刚" }
        if seconds < 3600 { return "\(Int(seconds / 60)) 分钟前" }
        if seconds < 86_400 { return "\(Int(seconds / 3600)) 小时前" }
        if seconds < 7 * 86_400 { return "\(Int(seconds / 86_400)) 天前" }
        return monthDay.string(from: date)
    }

    /// 时长：90 → “1 小时 30 分”
    static func duration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours) 小时" : "\(hours) 小时 \(rest) 分"
    }
}
