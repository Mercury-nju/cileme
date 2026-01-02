//
//  DictionaryService.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import Foundation

/// 词典API响应模型
struct DictionaryResponse: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]?
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

struct Meaning: Codable {
    let partOfSpeech: String?
    let definitions: [Definition]?
}

struct Definition: Codable {
    let definition: String?
    let example: String?
}

/// 单词查询结果
struct WordLookupResult {
    let word: String
    let phonetic: String
    let definition: String
    let audioURL: String?
    let isValid: Bool
}

/// 词典服务 - 使用 Free Dictionary API
class DictionaryService {
    static let shared = DictionaryService()
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    
    private init() {}
    
    /// 查询单词
    func lookup(_ word: String) async -> WordLookupResult {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard let url = URL(string: baseURL + trimmed) else {
            return WordLookupResult(word: trimmed, phonetic: "", definition: "", audioURL: nil, isValid: false)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return WordLookupResult(word: trimmed, phonetic: "", definition: "", audioURL: nil, isValid: false)
            }
            
            let results = try JSONDecoder().decode([DictionaryResponse].self, from: data)
            
            guard let first = results.first else {
                return WordLookupResult(word: trimmed, phonetic: "", definition: "", audioURL: nil, isValid: false)
            }
            
            // 提取音标
            let phonetic = first.phonetic ?? first.phonetics?.first(where: { $0.text != nil })?.text ?? ""
            
            // 提取音频URL
            let audioURL = first.phonetics?.first(where: { 
                $0.audio != nil && !$0.audio!.isEmpty 
            })?.audio
            
            // 提取第一个词义
            let definition = first.meanings?.first?.definitions?.first?.definition ?? ""
            
            return WordLookupResult(
                word: trimmed,
                phonetic: phonetic.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
                definition: definition,
                audioURL: audioURL,
                isValid: true
            )
        } catch {
            print("❌ 词典查询失败: \(error)")
            return WordLookupResult(word: trimmed, phonetic: "", definition: "", audioURL: nil, isValid: false)
        }
    }
    
    /// 仅验证单词是否存在
    func isValidWord(_ word: String) async -> Bool {
        let result = await lookup(word)
        return result.isValid
    }
}
