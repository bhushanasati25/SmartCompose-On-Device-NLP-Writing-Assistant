import SwiftUI

/// Distraction-free fullscreen writing mode with minimal chrome.
struct FocusModeView: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @State private var wordCount: Int = 0
    @State private var showControls: Bool = true

    let ghostRenderer: GhostTextRenderer
    let coordinator: RichTextCoordinator

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ComposeTextView(
                    text: $text,
                    ghostRenderer: ghostRenderer,
                    coordinator: coordinator,
                    onTextChange: { newText in
                        wordCount = newText.components(separatedBy: .whitespacesAndNewlines)
                            .filter { !$0.isEmpty }.count
                    }
                )
                .colorScheme(.dark)
            }

            // Minimal overlay controls
            if showControls {
                VStack {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Text("\(wordCount) words")
                            .font(Theme.metricsFont)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding()
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }
        .statusBarHidden(true)
    }
}
