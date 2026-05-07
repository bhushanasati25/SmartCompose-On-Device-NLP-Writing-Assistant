import SwiftUI

/// Displays writing goal progress with an animated ring and goal management.
struct WritingGoalView: View {
    let currentWordCount: Int
    @State private var goal: WritingGoal?
    @State private var showGoalPicker = false
    @State private var customTarget: String = ""

    var body: some View {
        VStack(spacing: 16) {
            if let goal = goal, goal.isActive {
                activeGoalView(goal)
            } else {
                noGoalView
            }
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .onAppear { goal = WritingGoal.load() }
        .sheet(isPresented: $showGoalPicker) { goalPickerSheet }
    }

    private func activeGoalView(_ goal: WritingGoal) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Theme.accent)
                Text("Writing Goal")
                    .font(.headline)
                Spacer()
                Button { clearGoal() } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 20) {
                // Animated progress ring
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(0.15), lineWidth: 8)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: min(goal.progress(currentWordCount: currentWordCount), 1.0))
                        .stroke(
                            goal.isAchieved(currentWordCount: currentWordCount) ? Color.green : Theme.accent,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(Theme.smoothEase, value: currentWordCount)

                    Text("\(Int(min(goal.progress(currentWordCount: currentWordCount), 1.0) * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentWordCount) / \(goal.targetWordCount) words")
                        .font(.subheadline.weight(.semibold))

                    if goal.isAchieved(currentWordCount: currentWordCount) {
                        Label("Goal achieved!", systemImage: "checkmark.circle.fill")
                            .font(Theme.captionFont)
                            .foregroundStyle(.green)
                    } else {
                        Text("\(goal.remainingWords(currentWordCount: currentWordCount)) words remaining")
                            .font(Theme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var noGoalView: some View {
        Button { showGoalPicker = true } label: {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(Theme.accent)
                Text("Set a Writing Goal")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var goalPickerSheet: some View {
        NavigationStack {
            List {
                Section("Presets") {
                    ForEach(WritingGoal.presets, id: \.label) { preset in
                        Button {
                            setGoal(preset.goal)
                            showGoalPicker = false
                        } label: {
                            HStack {
                                Text(preset.label)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                Section("Custom") {
                    HStack {
                        TextField("Word count", text: $customTarget)
                            .keyboardType(.numberPad)
                        Button("Set") {
                            if let target = Int(customTarget), target > 0 {
                                setGoal(WritingGoal(targetWordCount: target, isActive: true, createdAt: Date()))
                                showGoalPicker = false
                            }
                        }
                        .disabled(Int(customTarget) == nil)
                    }
                }
            }
            .navigationTitle("Writing Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showGoalPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func setGoal(_ newGoal: WritingGoal) {
        goal = newGoal
        newGoal.save()
        HapticManager.shared.documentAction()
    }

    private func clearGoal() {
        goal = nil
        WritingGoal.clear()
        HapticManager.shared.toolbarTap()
    }
}
