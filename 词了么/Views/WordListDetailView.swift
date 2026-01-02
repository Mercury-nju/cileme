//
//  WordListDetailView.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI

/// 单词表详情
struct WordListDetailView: View {
    private var dataService = DataService.shared
    private let pronunciationService = PronunciationService.shared
    
    @State private var wordList: WordList
    @State private var expandedWordId: UUID?
    @State private var editingWord: Word?
    @State private var showAddWord = false

    init(wordList: WordList) {
        _wordList = State(initialValue: wordList)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 分组标题 (日期)
                    HStack {
                        Text(wordList.formattedDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    // 单词列表
                    VStack(spacing: 12) {
                        ForEach(wordList.words) { word in
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
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        wordList.words.removeAll { $0.id == word.id }
                                        saveChanges()
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    // 底部计数
                    if !wordList.words.isEmpty {
                        Text("\(wordList.words.count) 个单词")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 30)
                    }
                }
                .padding(.bottom, 80)
            }
            
            // 右下角添加按钮
            Button {
                showAddWord = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle(wordList.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingWord) { word in
            NoteEditorView(word: word) { updatedWord in
                updateWord(updatedWord)
            }
        }
        .sheet(isPresented: $showAddWord) {
            AddWordSheet(wordList: $wordList, onSave: saveChanges)
                .presentationDetents([.medium])
        }
        .onDisappear {
            saveChanges()
        }
    }
    
    private func updateWord(_ updatedWord: Word) {
        if let index = wordList.words.firstIndex(where: { $0.id == updatedWord.id }) {
            wordList.words[index] = updatedWord
        }
    }
    
    private func saveChanges() {
        dataService.saveWordList(wordList)
    }
}

// MARK: - 添加单词弹窗
struct AddWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    private var dictionaryService = DictionaryService.shared
    private var dataService = DataService.shared
    
    @Binding var wordList: WordList
    var onSave: () -> Void
    
    init(wordList: Binding<WordList>, onSave: @escaping () -> Void) {
        self._wordList = wordList
        self.onSave = onSave
    }
    
    @State private var newWordText = ""
    @State private var isLoading = false
    @State private var showInvalidAlert = false
    @State private var showDuplicateAlert = false
    @State private var duplicateWordListTitle = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 输入框
                HStack {
                    TextField("输入单词...", text: $newWordText)
                        .font(.title3)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isInputFocused)
                        .onSubmit { addWord() }
                    
                    if isLoading {
                        ProgressView()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // 添加按钮
                Button {
                    addWord()
                } label: {
                    Text("添加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newWordText.isEmpty || isLoading ? Color.gray : Color.accentColor)
                        .cornerRadius(12)
                }
                .disabled(newWordText.isEmpty || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("添加单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
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
                isInputFocused = true
            }
        }
    }
    
    private func addWord() {
        let trimmed = newWordText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        
        // 检查当前列表中是否已有该单词
        if wordList.words.contains(where: { $0.text.lowercased() == trimmed }) {
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
                    wordList.words.append(word)
                    onSave()
                    newWordText = ""
                    dismiss()
                } else {
                    showInvalidAlert = true
                }
            }
        }
    }
}
