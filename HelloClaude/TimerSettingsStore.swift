//
//  TimerSettingsStore.swift
//  HelloClaude
//

import Foundation
import Combine

/// インターバルタイマーの設定を保持し、変更を永続化するストア。
final class TimerSettingsStore: ObservableObject {
    @Published var startHour: Int {
        didSet { UserDefaults.standard.set(startHour, forKey: Keys.startHour) }
    }
    @Published var startMinute: Int {
        didSet { UserDefaults.standard.set(startMinute, forKey: Keys.startMinute) }
    }
    @Published var endHour: Int {
        didSet { UserDefaults.standard.set(endHour, forKey: Keys.endHour) }
    }
    @Published var endMinute: Int {
        didSet { UserDefaults.standard.set(endMinute, forKey: Keys.endMinute) }
    }
    @Published var intervalMinutes: Int {
        didSet { UserDefaults.standard.set(intervalMinutes, forKey: Keys.intervalMinutes) }
    }
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    private enum Keys {
        static let startHour = "timer.startHour"
        static let startMinute = "timer.startMinute"
        static let endHour = "timer.endHour"
        static let endMinute = "timer.endMinute"
        static let intervalMinutes = "timer.intervalMinutes"
        static let isEnabled = "timer.isEnabled"
    }

    init() {
        let defaults = UserDefaults.standard
        startHour = defaults.object(forKey: Keys.startHour) as? Int ?? 8
        startMinute = defaults.object(forKey: Keys.startMinute) as? Int ?? 0
        endHour = defaults.object(forKey: Keys.endHour) as? Int ?? 20
        endMinute = defaults.object(forKey: Keys.endMinute) as? Int ?? 0
        intervalMinutes = defaults.object(forKey: Keys.intervalMinutes) as? Int ?? 60
        isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? false
    }

    var startDate: Date {
        get { Self.date(hour: startHour, minute: startMinute) }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            startHour = components.hour ?? 0
            startMinute = components.minute ?? 0
        }
    }

    var endDate: Date {
        get { Self.date(hour: endHour, minute: endMinute) }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            endHour = components.hour ?? 0
            endMinute = components.minute ?? 0
        }
    }

    /// 終了時刻が開始時刻以前の場合、日をまたぐ設定とみなす。
    var crossesMidnight: Bool {
        (endHour * 60 + endMinute) <= (startHour * 60 + startMinute)
    }

    /// 現在時刻を基準にした次回通知時刻を計算する（表示用）。
    func nextFireDate(from now: Date = Date()) -> Date? {
        guard isEnabled, intervalMinutes > 0 else { return nil }
        let calendar = Calendar.current

        let startTotal = startHour * 60 + startMinute
        var endTotal = endHour * 60 + endMinute
        if endTotal <= startTotal { endTotal += 24 * 60 }

        // 今日を起点に、開始〜終了（日またぎ含む）の全スロットを列挙し、
        // 明日分も合わせて現在時刻以降で最も近いものを選ぶ。
        var slotsFromMidnight: [Int] = []
        var minutes = startTotal
        while minutes <= endTotal {
            slotsFromMidnight.append(minutes % (24 * 60))
            minutes += intervalMinutes
        }

        let todayStart = calendar.startOfDay(for: now)
        let candidates = (0...1).flatMap { dayOffset in
            slotsFromMidnight.compactMap { totalMinutes -> Date? in
                calendar.date(byAdding: .minute, value: totalMinutes + dayOffset * 24 * 60, to: todayStart)
            }
        }

        return candidates.filter { $0 > now }.min()
    }

    private static func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
