//
//  WordList.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import Foundation

/// 单词表数据模型
struct WordList: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String          // 标题（默认为日期）
    var words: [Word]          // 单词数组
    var createdAt: Date        // 创建日期
    var updatedAt: Date        // 更新日期
    
    init(
        id: UUID = UUID(),
        title: String = "",
        words: [Word] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title.isEmpty ? Self.defaultTitle(for: createdAt) : title
        self.words = words
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 生成默认标题（基于日期）
    static func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 单词表"
        return formatter.string(from: date)
    }
    
    /// 格式化的创建日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: createdAt)
    }
    
    /// 单词数量描述
    var wordCountDescription: String {
        "\(words.count) 个单词"
    }
}
