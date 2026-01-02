//
//  PronunciationService.swift
//  词了么
//
//  Created by Mercury on 2025/12/16.
//

import Foundation
import AVFoundation
import Observation

/// 发音服务
@Observable
class PronunciationService {
    static let shared = PronunciationService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVPlayer?
    
    var isSpeaking = false
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }
    
    /// 播放单词发音（优先使用音频URL，否则使用TTS）
    func speak(_ text: String, audioURL: String? = nil) {
        // 如果有音频URL，使用真实发音
        if let urlString = audioURL, !urlString.isEmpty, let url = URL(string: urlString) {
            playAudio(from: url)
            return
        }
        
        // 否则使用TTS
        speakWithTTS(text)
    }
    
    /// 使用音频URL播放
    private func playAudio(from url: URL) {
        isSpeaking = true
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
        
        // 监听播放完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isSpeaking = false
        }
    }
    
    /// 使用TTS朗读
    private func speakWithTTS(_ text: String, language: String = "en-US") {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSpeaking = false
        }
    }
    
    /// 停止播放
    func stop() {
        audioPlayer?.pause()
        audioPlayer = nil
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}
