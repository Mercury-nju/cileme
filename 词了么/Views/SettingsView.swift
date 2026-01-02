//
//  SettingsView.swift
//  词了么
//
//  Created by Mercury on 2025/12/17.
//

import SwiftUI
import MessageUI

/// 设置页面
struct SettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @State private var showMailComposer = false
    @State private var showCooperationSheet = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    private let supportEmail = "66597505@qq.com"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - 设置
                SettingsSectionHeader(title: "设置")
                
                VStack(spacing: 0) {
                    SettingsRowView(
                        icon: "bell.badge",
                        iconColor: .primary,
                        title: "记词提醒"
                    ) {
                        Toggle("", isOn: $reminderEnabled)
                            .labelsHidden()
                            .tint(.orange)
                    }
                    .onChange(of: reminderEnabled) { _, newValue in
                        handleReminderToggle(newValue)
                    }
                }
                .background(Color.white)
                
                // MARK: - 支持
                SettingsSectionHeader(title: "支持")
                
                VStack(spacing: 0) {
                    Button {
                        openMailComposer()
                    } label: {
                        SettingsRowView(
                            icon: "envelope",
                            iconColor: .primary,
                            title: "联系与支持"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    SettingsDivider()
                    
                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        SettingsRowView(
                            icon: "doc.text",
                            iconColor: .primary,
                            title: "使用条款"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    SettingsDivider()
                    
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        SettingsRowView(
                            icon: "lock",
                            iconColor: .primary,
                            title: "隐私政策"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white)
                
                // MARK: - 关于
                SettingsSectionHeader(title: "关于")
                
                VStack(spacing: 0) {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRowView(
                            icon: "info.circle",
                            iconColor: .primary,
                            title: "关于词了么"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    SettingsDivider()
                    
                    Button {
                        showCooperationSheet = true
                    } label: {
                        SettingsRowView(
                            icon: "heart",
                            iconColor: .primary,
                            title: "社媒合作"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white)
                
                // 版本号
                Text("版本 \(appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCooperationSheet) {
            CooperationSheetView(supportEmail: supportEmail)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipient: supportEmail,
                subject: "词了么 - 用户反馈",
                result: $mailResult
            )
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            NotificationService.shared.requestPermission { granted in
                if granted {
                    NotificationService.shared.scheduleDailyReminders()
                } else {
                    reminderEnabled = false
                }
            }
        } else {
            NotificationService.shared.cancelAllReminders()
        }
    }
    
    private func openMailComposer() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            UIPasteboard.general.string = supportEmail
        }
    }
}

// MARK: - 社媒合作弹窗
struct CooperationSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let supportEmail: String
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Text("社媒合作")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top, 24)
            
            Text("如果你觉得词了么还不错并且想要发到社交媒体上的话，请联系我们，未来会赠送完整的高级会员，提供完整的体验。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer()
            
            Button {
                openMailComposer()
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("发送邮件")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipient: supportEmail,
                subject: "词了么 - 社媒合作",
                result: $mailResult
            )
        }
    }
    
    private func openMailComposer() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            UIPasteboard.general.string = supportEmail
        }
    }
}

// MARK: - 邮件编辑器
struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.dismiss()
        }
    }
}

// MARK: - 使用条款
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("使用条款")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("最后更新：2025年12月")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("""
欢迎使用词了么！

使用本应用即表示您同意以下条款：

1. 服务说明
词了么是一款帮助用户记录和学习英语单词的工具应用。

2. 用户责任
用户应合法使用本应用，不得用于任何违法目的。

3. 知识产权
本应用的所有内容、设计和代码均受知识产权法保护。

4. 免责声明
本应用按"现状"提供，不对服务的持续性、准确性作任何保证。

5. 条款修改
我们保留随时修改这些条款的权利。

如有疑问，请联系：66597505@qq.com
""")
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("使用条款")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - 隐私政策
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("用户协议与隐私政策")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("最后更新：2025年12月")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("""
词了么尊重并保护您的隐私。

1. 信息收集
我们不会收集您的个人身份信息。您的单词数据仅存储在您的设备本地。

2. 数据存储
所有单词记录均保存在您的设备上，不会上传至任何服务器。

3. 第三方服务
本应用使用第三方词典API获取单词释义，该过程仅传输查询的单词，不涉及个人信息。

4. 通知权限
如您开启记词提醒，我们将使用系统通知功能，但不会收集任何通知相关数据。

5. 麦克风权限
语音输入功能需要麦克风权限，录音数据仅用于语音识别，不会存储或上传。

6. 联系我们
如有隐私相关问题，请联系：66597505@qq.com
""")
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - 关于词了么
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("词了么")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("随时随地，记录新词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("我们的故事")
                        .font(.headline)
                    
                    Text("""
词了么诞生于一个简单的想法：让记单词变得像记笔记一样自然。

我们相信，学习英语不应该是枯燥的背诵，而是在生活中遇到新词时，能够快速记录、轻松回顾。

无论是阅读文章时遇到的生词，还是看剧时听到的新表达，词了么都能帮你第一时间捕捉，让每一个新词都不再溜走。

简单、纯粹、专注——这就是词了么。
""")
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - 设置页面组件
struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

struct SettingsRowView<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let accessory: Accessory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            accessory
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 56)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
