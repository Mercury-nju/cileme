//
//  RecordingView.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI

/// 记录页面
struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    private var dataService = DataService.shared
    private var dictionaryService = DictionaryService.shared

    @State private var draft: WordList
    @State private var newWordText = ""
    @State private var editingWord: Word?
    @State private var expandedWordId: UUID?
    @State private var isLoading = false
    @State private var showInvalidAlert = false
    @State private var showDuplicateAlert = false
    @State private var duplicateWordListTitle = ""
    @State private var hasSaved = false
    @State private var isDetailMode = false
    @FocusState private var isInputFocused: Bool

    init() {
        _draft = State(initialValue: WordList(title: "", words: []))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. 列表内容 (包含顶部的日期、中间的单词、末尾的输入框)
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(spacing: 0) {
                                // 顶部日期
                                HStack {
                                    Text(todayString)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                .padding(.bottom, 12)
                                
                                // 单词列表
                                VStack(spacing: 12) {
                                    ForEach(draft.words) { word in
                                        WordRowView(
                                            word: word,
                                            isExpanded: expandedWordId == word.id,
                                            onTap: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    expandedWordId = expandedWordId == word.id ? nil : word.id
                                                }
                                            },
                                            onEdit: {
                                                editingWord = word
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                        .id(word.id)
                                    }
                                }
                                
                                // 3. 输入框：仅在录入模式下显示
                                if !isDetailMode {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 12) {
                                            TextField("添加新单词...", text: $newWordText)
                                                .font(.body)
                                                .textInputAutocapitalization(.never)
                                                .autocorrectionDisabled()
                                                .focused($isInputFocused)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 16)
                                                .background(Color.white)
                                                .cornerRadius(12)
                                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                .onSubmit { addWord() }
                                            
                                            if isLoading {
                                                ProgressView()
                                                    .frame(width: 38, height: 38)
                                            } else if !newWordText.isEmpty {
                                                Button { addWord() } label: {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 38, height: 38)
                                                        .background(Color.accentColor)
                                                        .clipShape(Circle())
                                                }
                                                .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .id("bottom_input") // 自动滚动锚点
                                }
                                
                                if !draft.words.isEmpty {
                                    Text("\(draft.words.count) 个单词")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, isDetailMode ? 30 : 40)
                                }
                            }
                            .onChange(of: draft.words.count) { _ in
                                withAnimation(.spring()) {
                                    proxy.scrollTo("bottom_input", anchor: .bottom)
                                }
                            }
                            .onChange(of: isInputFocused) { focused in
                                if focused {
                                    // 聚焦时也滚动到底部，防止键盘遮挡
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.spring()) {
                                            proxy.scrollTo("bottom_input", anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isDetailMode ? "查看单词" : "录入单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isDetailMode {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    } else {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isDetailMode {
                        // 进入详情模式后，展示标准的编辑按钮
                        EditButton()
                    } else {
                        Button("完成") {
                            saveWordList()
                        }
                        .fontWeight(.semibold)
                        .disabled(draft.words.isEmpty)
                    }
                }
            }
            .sheet(item: $editingWord) { word in
                NoteEditorView(word: word) { updatedWord in
                    updateWord(updatedWord)
                }
            }
            .alert("无效单词", isPresented: $showInvalidAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("\"\(newWordText)\" 不是有效的英文单词")
            }
            .alert("单词已存在", isPresented: $showDuplicateAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("\"\(newWordText)\" 已在「\(duplicateWordListTitle)」中记录过了")
            }
            .onAppear {
                // 仅在非详情模式下自动聚焦
                if !isDetailMode {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isInputFocused = true
                    }
                }
            }
        }
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: Date())
    }

    private func addWord() {
        let trimmed = newWordText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        // 检查当前草稿中是否已有该单词
        if draft.words.contains(where: { $0.text.lowercased() == trimmed }) {
            duplicateWordListTitle = "当前列表"
            showDuplicateAlert = true
            return
        }
        
        // 检查历史记录中是否已有该单词
        if let existingListTitle = dataService.findExistingWord(trimmed) {
            duplicateWordListTitle = existingListTitle
            showDuplicateAlert = true
            return
        }
        
        // 格式校验
        let pattern = "^[a-zA-Z][a-zA-Z'-]*$|^[a-zA-Z]$"
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            showInvalidAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            let result = await dictionaryService.lookup(trimmed)
            
            await MainActor.run {
                isLoading = false
                
                if result.isValid {
                    let word = Word(
                        text: result.word,
                        definition: result.definition,
                        pronunciation: result.phonetic,
                        audioURL: result.audioURL ?? ""
                    )
                    
                    // 立即清空输入框，防止再次点击触发或“继承”错觉
                    newWordText = ""
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        draft.words.append(word)
                        // 振动反馈
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else {
                    showInvalidAlert = true
                }
            }
        }
    }

    private func updateWord(_ updatedWord: Word) {
        if let index = draft.words.firstIndex(where: { $0.id == updatedWord.id }) {
            draft.words[index] = updatedWord
        }
    }

    private func saveWordList() {
        guard !draft.words.isEmpty else { return }
        dataService.saveWordList(draft)
        hasSaved = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // 切换到详情查看模式
        withAnimation {
            isInputFocused = false
            isDetailMode = true
        }
    }
    
    private func saveAndDismiss() {
        guard !draft.words.isEmpty, !hasSaved else {
            dismiss()
            return
        }
        dataService.saveWordList(draft)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - 笔记编辑视图
struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var word: Word
    let onSave: (Word) -> Void

    init(word: Word, onSave: @escaping (Word) -> Void) {
        _word = State(initialValue: word)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                Form {
                    Section("单词") {
                        HStack {
                            Text(word.text)
                                .font(.headline)
                            if !word.pronunciation.isEmpty {
                                Text("/\(word.pronunciation)/")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if !word.definition.isEmpty {
                        Section("英文释义") {
                            Text(word.definition)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section("中文翻译") {
                        TextField("输入你的中文翻译...", text: $word.note, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(word)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    RecordingView()
}
