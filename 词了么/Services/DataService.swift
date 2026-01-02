//
//  DataService.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import Foundation
import SwiftUI
import Observation

/// 数据持久化服务
@Observable
class DataService {
    static let shared = DataService()
    
    private let wordListsKey = "savedWordLists"
    private let currentDraftKey = "currentDraft"
    
    var wordLists: [WordList] = []
    var currentDraft: WordList?
    
    private init() {
        loadAllWordLists()
        loadCurrentDraft()
    }
    
    // MARK: - Word Lists
    
    /// 加载所有历史单词表
    func loadAllWordLists() {
        guard let data = UserDefaults.standard.data(forKey: wordListsKey) else {
            wordLists = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([WordList].self, from: data)
            wordLists = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("❌ 加载单词表失败: \(error)")
            wordLists = []
        }
    }
    
    /// 保存单词表
    func saveWordList(_ wordList: WordList) {
        // 如果单词表为空，则直接删除
        if wordList.words.isEmpty {
            deleteWordList(wordList)
            return
        }
        
        if let index = wordLists.firstIndex(where: { $0.id == wordList.id }) {
            var updated = wordList
            updated.updatedAt = Date()
            wordLists[index] = updated
        } else {
            wordLists.insert(wordList, at: 0)
        }
        persistWordLists()
    }
    
    /// 删除单词表
    func deleteWordList(_ wordList: WordList) {
        wordLists.removeAll { $0.id == wordList.id }
        persistWordLists()
    }
    
    /// 删除多个单词表
    func deleteWordLists(at offsets: IndexSet) {
        wordLists.remove(atOffsets: offsets)
        persistWordLists()
    }
    
    private func persistWordLists() {
        do {
            let data = try JSONEncoder().encode(wordLists)
            UserDefaults.standard.set(data, forKey: wordListsKey)
        } catch {
            print("❌ 保存单词表失败: \(error)")
        }
    }
    
    // MARK: - Draft
    
    /// 加载当前草稿
    func loadCurrentDraft() {
        guard let data = UserDefaults.standard.data(forKey: currentDraftKey) else {
            currentDraft = nil
            return
        }
        
        do {
            currentDraft = try JSONDecoder().decode(WordList.self, from: data)
        } catch {
            print("❌ 加载草稿失败: \(error)")
            currentDraft = nil
        }
    }
    
    /// 保存草稿（自动保存）
    func saveDraft(_ draft: WordList) {
        currentDraft = draft
        
        do {
            let data = try JSONEncoder().encode(draft)
            UserDefaults.standard.set(data, forKey: currentDraftKey)
        } catch {
            print("❌ 保存草稿失败: \(error)")
        }
    }
    
    /// 清除草稿
    func clearDraft() {
        currentDraft = nil
        UserDefaults.standard.removeObject(forKey: currentDraftKey)
    }
    
    /// 将草稿保存为正式单词表
    func finalizeDraft() -> WordList? {
        guard let draft = currentDraft, !draft.words.isEmpty else {
            return nil
        }
        
        saveWordList(draft)
        clearDraft()
        return draft
    }
    
    // MARK: - Helpers
    
    /// 检查单词是否已存在（返回所在的单词表标题，如果不存在返回 nil）
    func findExistingWord(_ text: String) -> String? {
        let lowercased = text.lowercased()
        for wordList in wordLists {
            if wordList.words.contains(where: { $0.text.lowercased() == lowercased }) {
                return wordList.title
            }
        }
        return nil
    }
    
    /// 按日期分组的单词表
    var groupedWordLists: [(String, [WordList])] {
        let grouped = Dictionary(grouping: wordLists) { wordList -> String in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: wordList.createdAt)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
}
