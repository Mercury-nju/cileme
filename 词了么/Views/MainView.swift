//
//  MainView.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI

/// 主页 - 备忘录风格
struct MainView: View {
    private var dataService = DataService.shared
    @State private var showRecording = false
    @State private var showImport = false
    @State private var searchText = ""
    @State private var wordListToDelete: WordList?
    
    // 随机CTA文案
    private let ctaTexts = [
        "现在，记一个单词吧",
        "今天遇到什么新单词？",
        "记录刚刚遇到的单词吧"
    ]
    @State private var currentCTA: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if filteredGroupedLists.isEmpty {
                    emptyStateView
                } else {
                    wordListView
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .overlay(alignment: .bottomTrailing) {
                addButton
            }
            .navigationTitle(currentCTA)
            .searchable(text: $searchText, prompt: "搜索单词或列表")
            .onAppear {
                if currentCTA.isEmpty {
                    currentCTA = ctaTexts.randomElement() ?? ctaTexts[0]
                }
            }
            .confirmationDialog("确定删除这个单词表吗？", isPresented: .init(
                get: { wordListToDelete != nil },
                set: { if !$0 { wordListToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let wordList = wordListToDelete {
                        withAnimation {
                            dataService.deleteWordList(wordList)
                        }
                    }
                    wordListToDelete = nil
                }
                Button("取消", role: .cancel) {
                    wordListToDelete = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .navigationDestination(for: WordList.self) { wordList in
                WordListDetailView(wordList: wordList)
            }
            .fullScreenCover(isPresented: $showRecording) {
                RecordingView()
            }
            .sheet(isPresented: $showImport) {
                ImportView()
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "book.closed" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text(searchText.isEmpty ? "还没有单词" : "没有找到相关单词")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "点击右下角按钮开始记录" : "试试其他关键词")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 单词列表
    private var wordListView: some View {
        List {
            ForEach(filteredGroupedLists, id: \.title) { group in
                Section {
                    ForEach(group.lists) { wordList in
                        NavigationLink(value: wordList) {
                            WordListRowView(wordList: wordList)
                        }
                        .listRowBackground(AppTheme.cardColor(for: wordList.id))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                wordListToDelete = wordList
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(group.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - 添加按钮
    private var addButton: some View {
        Button {
            showRecording = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    // MARK: - 数据处理
    private var groupedLists: [(title: String, lists: [WordList])] {
        let calendar = Calendar.current
        let now = Date()
        var groups: [String: [WordList]] = [:]
        let order = ["今天", "昨天", "过去7天", "过去30天", "更早"]

        for list in dataService.wordLists {
            let key: String
            if calendar.isDateInToday(list.createdAt) {
                key = "今天"
            } else if calendar.isDateInYesterday(list.createdAt) {
                key = "昨天"
            } else if let diff = calendar.dateComponents([.day], from: list.createdAt, to: now).day, diff <= 7 {
                key = "过去7天"
            } else if let diff = calendar.dateComponents([.day], from: list.createdAt, to: now).day, diff <= 30 {
                key = "过去30天"
            } else {
                key = "更早"
            }
            groups[key, default: []].append(list)
        }

        return order.compactMap { key in
            guard let lists = groups[key], !lists.isEmpty else { return nil }
            return (title: key, lists: lists)
        }
    }
    
    private var filteredGroupedLists: [(title: String, lists: [WordList])] {
        guard !searchText.isEmpty else { return groupedLists }
        
        let query = searchText.lowercased()
        return groupedLists.compactMap { group in
            let filtered = group.lists.filter { wordList in
                if wordList.title.lowercased().contains(query) { return true }
                return wordList.words.contains { word in
                    word.text.lowercased().contains(query) ||
                    word.note.lowercased().contains(query)
                }
            }
            return filtered.isEmpty ? nil : (title: group.title, lists: filtered)
        }
    }
}

// MARK: - 单词表行视图
struct WordListRowView: View {
    let wordList: WordList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(wordList.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(wordList.words.prefix(4).map { $0.text }.joined(separator: "、"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Text(wordList.wordCountDescription)
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MainView()
}
