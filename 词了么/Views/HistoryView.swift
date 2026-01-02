//
//  HistoryView.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import SwiftUI

/// 历史记录 - iOS原生风格
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    private var dataService = DataService.shared
    @State private var selectedWordList: WordList?

    var body: some View {
        NavigationStack {
            List {
                if dataService.wordLists.isEmpty {
                    ContentUnavailableView(
                        "没有单词表",
                        systemImage: "doc.text",
                        description: Text("完成记录后会显示在这里")
                    )
                } else {
                    ForEach(groupedLists, id: \.title) { group in
                        Section(group.title) {
                            ForEach(group.lists) { wordList in
                                Button {
                                    selectedWordList = wordList
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(wordList.title)
                                            .foregroundColor(.primary)
                                        HStack(spacing: 8) {
                                            Text(formatTime(wordList.createdAt))
                                            Text(wordList.words.map { $0.text }.prefix(3).joined(separator: "、"))
                                                .lineLimit(1)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        dataService.deleteWordList(wordList)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(item: $selectedWordList) { wordList in
                WordListDetailView(wordList: wordList)
            }
        }
    }

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

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
}
