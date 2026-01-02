//
//  Theme.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI

/// 应用主题
enum AppTheme {
    // 背景色 - 淡黄色
    static let background = Color(red: 1.0, green: 0.98, blue: 0.94)
    
    // 卡片色块 - 柔和纯色
    static let cardColors: [Color] = [
        Color(red: 0.98, green: 0.92, blue: 0.84),  // 淡橙
        Color(red: 0.90, green: 0.95, blue: 0.92),  // 淡绿
        Color(red: 0.92, green: 0.92, blue: 0.98),  // 淡紫
        Color(red: 0.95, green: 0.90, blue: 0.92),  // 淡粉
        Color(red: 0.90, green: 0.95, blue: 0.98),  // 淡蓝
        Color(red: 0.98, green: 0.96, blue: 0.88),  // 淡黄
    ]
    
    /// 根据索引获取颜色
    static func cardColor(for index: Int) -> Color {
        cardColors[index % cardColors.count]
    }
    
    /// 根据ID获取稳定颜色
    static func cardColor(for id: UUID) -> Color {
        let hash = abs(id.hashValue)
        return cardColors[hash % cardColors.count]
    }
}
