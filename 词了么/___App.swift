//
//  词了么App.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI

@main
struct CiLeMeApp: App {
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    
    init() {
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
    
    private func setupNotifications() {
        // 如果用户开启了提醒，安排通知
        if UserDefaults.standard.object(forKey: "reminderEnabled") == nil {
            // 首次启动，请求权限
            NotificationService.shared.requestPermission { granted in
                if granted {
                    NotificationService.shared.scheduleDailyReminders()
                }
            }
        } else if UserDefaults.standard.bool(forKey: "reminderEnabled") {
            // 已开启提醒，重新安排通知
            NotificationService.shared.scheduleDailyReminders()
        }
    }
}
