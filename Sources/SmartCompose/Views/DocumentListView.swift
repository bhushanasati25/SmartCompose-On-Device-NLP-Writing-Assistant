import SwiftUI

/// Document browser with search, sort, and swipe-to-delete functionality.
@MainActor
struct DocumentListView: View {

    @Bindable var viewModel: DocumentListViewModel
    @State private var selectedDocument: Document?
    @State private var showingSortPicker = false
    @State private var showingTemplatePicker = false
    @State private var animateSparkles = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.canvasBackground.ignoresSafeArea()

                if viewModel.filteredDocuments.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle("SmartCompose")
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search documents..."
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(DocumentListViewModel.SortOrder.allCases, id: \.self) { order in
                            Button {
                                withAnimation(Theme.standardSpring) {
                                    viewModel.sortOrder = order
                                }
                            } label: {
                                Label(order.rawValue, systemImage: order.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Sort Documents")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolEffect(.bounce, value: animateSparkles)
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("New Document")
                }
            }
            .refreshable {
                viewModel.loadDocuments()
            }
            .navigationDestination(item: $selectedDocument) { document in
                ComposeView(
                    viewModel: ComposeViewModel(document: document),
                    onSave: { viewModel.loadDocuments() }
                )
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView { template in
                    let newDoc = viewModel.createDocument()
                    newDoc.title = template.suggestedTitle
                    newDoc.content = template.content
                    selectedDocument = newDoc
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Document List

    private var documentList: some View {
        List {
            // Stats header
            if !viewModel.documents.isEmpty {
                statsHeader
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.filteredDocuments) { document in
                Button {
                    selectedDocument = document
                } label: {
                    DocumentRowView(document: document)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .padding(.vertical, Theme.listSpacing)
                        .padding(.horizontal, 8)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation(Theme.standardSpring) {
                            viewModel.deleteDocument(document)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Theme.canvasBackground)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatPill(
                icon: "doc.text",
                value: "\(viewModel.documents.count)",
                label: "Documents"
            )
            StatPill(
                icon: "text.word.spacing",
                value: "\(viewModel.totalWordCount)",
                label: "Total Words"
            )
        }
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Documents", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Create a new document to start writing with intelligent predictions.")
        } actions: {
            NavigationLink {
                ComposeView(
                    viewModel: ComposeViewModel(document: viewModel.createDocument()),
                    onSave: { viewModel.loadDocuments() }
                )
            } label: {
                Text("Create Document")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Stat Pill Component

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.metricsFont)
                    .foregroundStyle(.primary)
                Text(label)
                    .font(Theme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.pillCornerRadius))
    }
}
