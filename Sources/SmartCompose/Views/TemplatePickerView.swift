import SwiftUI

/// Modal sheet for selecting a writing template when creating a new document.
struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (WritingTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(WritingTemplate.allCases) { template in
                    Button {
                        HapticManager.shared.documentAction()
                        onSelect(template)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: template.icon)
                                .font(.title3)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 36, height: 36)
                                .background(Theme.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(template.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(template.subtitle)
                                    .font(Theme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
