//
//  Word.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import Foundation

/// 单词数据模型
struct Word: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var text: String           // 单词文本
    var definition: String     // 词义
    var note: String           // 注释（可选）
    var pronunciation: String  // 音标（可选）
    var audioURL: String       // 发音音频URL（可选）
    var createdAt: Date        // 创建时间
    
    init(
        id: UUID = UUID(),
        text: String,
        definition: String = "",
        note: String = "",
        pronunciation: String = "",
        audioURL: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.definition = definition
        self.note = note
        self.pronunciation = pronunciation
        self.audioURL = audioURL
        self.createdAt = createdAt
    }
}
