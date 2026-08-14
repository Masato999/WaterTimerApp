//
//  NotificationManager.swift
//  HelloClaude
//

import Foundation
import UserNotifications

/// 指定した時間帯・間隔で毎日繰り返すローカル通知のスケジューリングを担当する。
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    /// UNCalendarNotificationTrigger は1日1回×繰り返しの単位でしか組めないため、
    /// 時間帯内のスロットごとに1件ずつ通知を登録する。iOS の同時保留上限は64件。
    private let maxScheduledNotifications = 64
    private let identifierPrefix = "com.masato999.HelloClaude.interval."

    private var center: UNUserNotificationCenter { .current() }

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    func apply(_ settings: TimerSettingsStore) {
        cancelAll()
        guard settings.isEnabled, settings.intervalMinutes > 0 else { return }

        let startTotal = settings.startHour * 60 + settings.startMinute
        var endTotal = settings.endHour * 60 + settings.endMinute
        if endTotal <= startTotal { endTotal += 24 * 60 }

        var minutes = startTotal
        var index = 0
        while minutes <= endTotal, index < maxScheduledNotifications {
            let normalized = minutes % (24 * 60)

            var dateComponents = DateComponents()
            dateComponents.hour = normalized / 60
            dateComponents.minute = normalized % 60

            let content = UNMutableNotificationContent()
            content.title = "記録の時間です"
            content.body = "トレーニング・食事の記録をつけましょう"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)

            minutes += settings.intervalMinutes
            index += 1
        }
    }

    func cancelAll() {
        center.getPendingNotificationRequests { [identifierPrefix] requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(identifierPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // アプリがフォアグラウンドにいても通知バナー・サウンドを表示する
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
