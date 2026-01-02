//
//  NotificationService.swift
//  词了么
//
//  Created by Mercury on 2025/12/17.
//

import Foundation
import UserNotifications

/// 通知服务
class NotificationService {
    static let shared = NotificationService()
    
    private let notificationMessages = [
        "发现好词了？记下来吧！",
        "把刚遇到的单词写下吧～",
        "今天学了什么单词呀？记下来吧",
        "你的单词表在这里，随时可以翻看"
    ]
    
    // 通知时间：7:30, 12:30, 19:00, 23:00
    private let notificationTimes: [(hour: Int, minute: Int)] = [
        (7, 30),
        (12, 30),
        (19, 0),
        (23, 0)
    ]
    
    private init() {}
    
    /// 请求通知权限
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// 安排每日提醒通知
    func scheduleDailyReminders() {
        // 先移除所有已安排的通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for (index, time) in notificationTimes.enumerated() {
            scheduleNotification(at: time.hour, minute: time.minute, identifier: "reminder_\(index)")
        }
    }
    
    /// 取消所有提醒
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleNotification(at hour: Int, minute: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "词了么"
        content.body = notificationMessages.randomElement() ?? notificationMessages[0]
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 安排通知失败: \(error)")
            }
        }
    }
    
    /// 检查通知权限状态
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}
