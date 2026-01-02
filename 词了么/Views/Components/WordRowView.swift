//
//  WordRowView.swift
//  词了么
//
//  Created by Mercury on 2025/12/22.
//

import SwiftUI

/// 统一的单词行视图组件
struct WordRowView: View {
    let word: Word
    let isExpanded: Bool
    var onTap: () -> Void
    var onEdit: () -> Void
    
    private let pronunciationService = PronunciationService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶层容器：白底卡片
            VStack(alignment: .leading, spacing: 0) {
                // 1. 标题概要 (始终保持静止)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(word.text)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if !word.pronunciation.isEmpty {
                                Text("/\(word.pronunciation)/")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 发音按钮
                            Button {
                                pronunciationService.speak(word.text, audioURL: word.audioURL.isEmpty ? nil : word.audioURL)
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        if !word.note.isEmpty {
                            Text(word.note)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
                
                // 2. 详情内容 (自然展开 - 采用录入页面的简洁风格)
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.bottom, 4)
                        
                        if !word.definition.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("英文释义")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Text(word.definition)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // 编辑按钮
                        HStack {
                            Spacer()
                            Button(action: onEdit) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                    Text("编辑笔记")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                            .controlSize(.small)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        }
    }
}
