import AVFoundation
import Foundation

/// On-device text-to-speech service using AVSpeechSynthesizer.
@MainActor
final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    @Published var state: SpeechState = .idle
    @Published var rate: Float = 0.5
    @Published var pitch: Float = 1.0
    @Published var progress: Double = 0.0

    private var totalCharacters: Int = 0

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        totalCharacters = text.count
        progress = 0.0

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.pitchMultiplier = pitch
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        synthesizer.speak(utterance)
        state = .speaking
    }

    func pause() {
        if synthesizer.isSpeaking { synthesizer.pauseSpeaking(at: .word); state = .paused }
    }

    func resume() {
        if synthesizer.isPaused { synthesizer.continueSpeaking(); state = .speaking }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate); state = .idle; progress = 0.0
    }

    func togglePlayPause(_ text: String) {
        switch state {
        case .idle: speak(text)
        case .speaking: pause()
        case .paused: resume()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.progress = Double(characterRange.location + characterRange.length) / Double(max(self.totalCharacters, 1))
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.state = .idle; self.progress = 1.0 }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.state = .idle; self.progress = 0.0 }
    }
}

enum SpeechState: Equatable {
    case idle, speaking, paused
    var icon: String {
        switch self { case .idle: return "play.fill"; case .speaking: return "pause.fill"; case .paused: return "play.fill" }
    }
    var label: String {
        switch self { case .idle: return "Read Aloud"; case .speaking: return "Pause"; case .paused: return "Resume" }
    }
}
