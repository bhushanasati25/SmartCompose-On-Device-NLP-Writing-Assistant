import SwiftUI

/// A card-style row displaying document metadata in the document list.
struct DocumentRowView: View {

    let document: Document
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack {
                Text(document.title)
                    .font(Theme.titleFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Language badge
                if let language = document.detectedLanguage {
                    Text(language.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.accent.opacity(0.15))
                        .foregroundStyle(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Preview snippet
            if !document.snippet.isEmpty {
                Text(document.snippet)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Metadata row
            HStack(spacing: 12) {
                // Word count
                Label("\(document.wordCount) words", systemImage: "text.word.spacing")
                    .font(Theme.captionFont)
                    .foregroundStyle(.tertiary)

                Spacer()

                // Last modified
                Text(document.formattedDate)
                    .font(Theme.captionFont)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.cardPadding)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(Theme.standardSpring) {
                appeared = true
            }
        }
    }
}
