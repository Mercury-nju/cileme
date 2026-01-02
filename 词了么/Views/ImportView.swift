//
//  ImportView.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI
import UniformTypeIdentifiers

/// 导入单词视图
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    private var dataService = DataService.shared
    private var dictionaryService = DictionaryService.shared
    
    @State private var inputText = ""
    @State private var parsedWords: [String] = []
    @State private var validatedWords: [Word] = []
    @State private var isValidating = false
    @State private var validationProgress = 0.0
    @State private var showResult = false
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !showResult {
                        inputSection
                    } else {
                        resultSection
                    }
                }
            }
            .navigationTitle("导入单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                if showResult && !validatedWords.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("导入") {
                            importWords()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    // MARK: - 输入区域
    private var inputSection: some View {
        VStack(spacing: 16) {
            // 说明
            VStack(alignment: .leading, spacing: 8) {
                Text("导入单词")
                    .font(.headline)
                
                Text("从文件导入或直接粘贴，每行一个单词")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 导入方式按钮
            HStack(spacing: 12) {
                Button {
                    showFilePicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 28))
                        Text("选择文件")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button {
                    if let clipboard = UIPasteboard.general.string {
                        inputText = clipboard
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 28))
                        Text("粘贴文本")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            
            // 输入框
            TextEditor(text: $inputText)
                .font(.system(size: 16, design: .monospaced))
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if inputText.isEmpty {
                            Text("在此输入或粘贴单词列表...")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.leading, 16)
                                .padding(.top, 20)
                        }
                    },
                    alignment: .topLeading
                )
                .padding(.horizontal, 20)
            
            // 清空按钮
            if !inputText.isEmpty {
                Button {
                    inputText = ""
                } label: {
                    Label("清空", systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            Spacer()
            
            // 解析按钮
            Button {
                parseAndValidate()
            } label: {
                if isValidating {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("验证中... \(Int(validationProgress * 100))%")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                } else {
                    Text("解析单词")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputText.isEmpty ? Color.secondary : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(inputText.isEmpty || isValidating)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 结果区域
    private var resultSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("找到 \(validatedWords.count) 个有效单词")
                        .font(.headline)
                    if parsedWords.count > validatedWords.count {
                        Text("\(parsedWords.count - validatedWords.count) 个无效已过滤")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                Button("重新输入") {
                    showResult = false
                    validatedWords = []
                }
                .font(.subheadline)
            }
            .padding(20)
            
            List {
                ForEach(validatedWords) { word in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(word.text)
                                .font(.headline)
                            if !word.pronunciation.isEmpty {
                                Text("/\(word.pronunciation)/")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if !word.definition.isEmpty {
                            Text(word.definition)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    validatedWords.remove(atOffsets: offsets)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - 文件导入处理
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // 获取文件访问权限
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                inputText = content
            } catch {
                print("❌ 读取文件失败: \(error)")
            }
            
        case .failure(let error):
            print("❌ 文件选择失败: \(error)")
        }
    }
    
    // MARK: - 解析和验证
    private func parseAndValidate() {
        // 按行解析，每行提取英文单词和中文翻译
        let lines = inputText.components(separatedBy: .newlines)
        var parsedEntries: [(word: String, note: String)] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // 提取英文单词（第一个连续英文字母序列）
            let wordPattern = "[a-zA-Z][a-zA-Z'-]*"
            guard let wordMatch = trimmed.range(of: wordPattern, options: .regularExpression) else { continue }
            let word = String(trimmed[wordMatch]).lowercased()
            
            // 提取中文翻译（所有中文字符及标点）
            let chinesePattern = "[\\u4e00-\\u9fa5]+"
            var note = ""
            if let chineseRange = trimmed.range(of: chinesePattern, options: .regularExpression) {
                note = String(trimmed[chineseRange])
            }
            
            parsedEntries.append((word: word, note: note))
        }
        
        // 去重（保留第一个出现的）
        var seen = Set<String>()
        parsedEntries = parsedEntries.filter { entry in
            if seen.contains(entry.word) { return false }
            seen.insert(entry.word)
            return true
        }
        
        parsedWords = parsedEntries.map { $0.word }
        
        guard !parsedEntries.isEmpty else {
            showResult = true
            return
        }
        
        isValidating = true
        validatedWords = []
        validationProgress = 0
        
        Task {
            for (index, entry) in parsedEntries.enumerated() {
                let result = await dictionaryService.lookup(entry.word)
                
                await MainActor.run {
                    validationProgress = Double(index + 1) / Double(parsedEntries.count)
                    
                    if result.isValid {
                        let word = Word(
                            text: result.word,
                            definition: result.definition,
                            note: entry.note,
                            pronunciation: result.phonetic,
                            audioURL: result.audioURL ?? ""
                        )
                        validatedWords.append(word)
                    }
                }
            }
            
            await MainActor.run {
                isValidating = false
                showResult = true
            }
        }
    }
    
    // MARK: - 导入
    private func importWords() {
        guard !validatedWords.isEmpty else { return }
        
        let wordList = WordList(words: validatedWords)
        dataService.saveWordList(wordList)
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

#Preview {
    ImportView()
}
