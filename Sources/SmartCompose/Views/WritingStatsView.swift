import SwiftUI

/// Dashboard displaying real-time writing analytics and metrics.
struct WritingStatsView: View {

    let metrics: WritingMetrics
    let toneResult: ToneResult?
    let isAnalyzing: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Word count and reading time
                metricsGrid

                // Readability gauge
                readabilitySection

                // Sentiment indicator
                sentimentSection

                // Tone Analysis
                ToneAnalysisView(toneResult: toneResult, isAnalyzing: isAnalyzing)

                // Writing Goal Progress
                WritingGoalView(currentWordCount: metrics.wordCount)

                // Entities
                if !metrics.entities.isEmpty {
                    entitiesSection
                }

                // Suggestion stats
                suggestionSection
            }
            .padding()
        }
        .background(Theme.canvasBackground)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(
                icon: "text.word.spacing",
                value: "\(metrics.wordCount)",
                label: "Words",
                color: .blue
            )
            MetricCard(
                icon: "text.justify.left",
                value: "\(metrics.sentenceCount)",
                label: "Sentences",
                color: .indigo
            )
            MetricCard(
                icon: "paragraphsign",
                value: "\(metrics.paragraphCount)",
                label: "Paragraphs",
                color: .purple
            )
            MetricCard(
                icon: "character.cursor.ibeam",
                value: "\(metrics.characterCount)",
                label: "Characters",
                color: .teal
            )
            MetricCard(
                icon: "clock",
                value: String(format: "%.1f min", metrics.estimatedReadingTime),
                label: "Read Time",
                color: .orange
            )
            MetricCard(
                icon: "text.line.first.and.arrowtriangle.forward",
                value: String(format: "%.1f", metrics.averageSentenceLength),
                label: "Avg Length",
                color: .cyan
            )
        }
    }

    // MARK: - Readability Section

    private var readabilitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: metrics.readabilityLabel.iconName)
                    .foregroundStyle(readabilityColor)
                Text("Readability")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(readabilityColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: metrics.readabilityScore / 100.0)
                        .stroke(readabilityColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(Theme.smoothEase, value: metrics.readabilityScore)

                    Text("\(Int(metrics.readabilityScore))")
                        .font(Theme.metricsFont)
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(metrics.readabilityLabel.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Flesch Reading Ease Score")
                        .font(Theme.captionFont)
                        .foregroundStyle(.secondary)

                    if let lang = metrics.detectedLanguage {
                        Text("Language: \(Locale.current.localizedString(forLanguageCode: lang) ?? lang)")
                            .font(Theme.captionFont)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    private var readabilityColor: Color {
        switch metrics.readabilityLabel {
        case .veryEasy, .easy: return .green
        case .fairlyEasy, .standard: return .blue
        case .fairlyDifficult: return .orange
        case .difficult, .veryDifficult: return .red
        }
    }

    // MARK: - Sentiment Section

    private var sentimentSection: some View {
        HStack(spacing: 16) {
            Image(systemName: sentimentIcon)
                .font(.title2)
                .foregroundStyle(Theme.sentimentColor(for: metrics.sentimentScore))

            VStack(alignment: .leading, spacing: 4) {
                Text("Sentiment: \(metrics.sentimentLabel)")
                    .font(.subheadline.weight(.semibold))

                Text(String(format: "Score: %.2f", metrics.sentimentScore))
                    .font(Theme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Sentiment bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.sentimentColor(for: metrics.sentimentScore))
                        .frame(
                            width: geometry.size.width * CGFloat((metrics.sentimentScore + 1) / 2),
                            height: 8
                        )
                        .animation(Theme.smoothEase, value: metrics.sentimentScore)
                }
            }
            .frame(width: 80, height: 8)
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    private var sentimentIcon: String {
        switch metrics.sentimentScore {
        case ..<(-0.3): return "face.smiling.inverse"
        case (-0.3)..<0.3: return "face.smiling"
        default: return "face.smiling.fill"
        }
    }

    // MARK: - Entities Section

    private var entitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Theme.secondaryAccent)
                Text("Entities")
                    .font(.headline)
                Spacer()
            }

            FlowLayout(spacing: 8) {
                ForEach(metrics.entities) { entity in
                    HStack(spacing: 4) {
                        Image(systemName: entity.type.iconName)
                            .font(.caption2)
                        Text(entity.text)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.entityColor(for: entity.type).opacity(0.15))
                    .foregroundStyle(Theme.entityColor(for: entity.type))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    // MARK: - Suggestion Stats

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                Text("Predictions")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack {
                    Text("\(metrics.suggestionsAccepted)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.green)
                    Text("Accepted")
                        .font(Theme.captionFont)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(metrics.suggestionsDismissed)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.orange)
                    Text("Dismissed")
                        .font(Theme.captionFont)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack {
                    Text(String(format: "%.0f%%", metrics.acceptanceRate))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Text("Accept Rate")
                        .font(Theme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(Theme.metricsFont)
                .foregroundStyle(.primary)

            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout

/// A layout that wraps elements horizontally, flowing to new lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func computeLayout(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = max(totalHeight, currentY + lineHeight)
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}
