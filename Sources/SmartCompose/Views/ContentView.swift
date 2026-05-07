import SwiftUI

/// Root view with tab-based navigation for Documents, Compose, and Settings.
@MainActor
struct ContentView: View {

    @State private var selectedTab: Tab = .documents
    @State private var documentListVM: DocumentListViewModel

    init() {
        _documentListVM = State(wrappedValue: DocumentListViewModel())
    }
    @State private var animateTab = false

    enum Tab: String {
        case documents, compose, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // DOCUMENTS TAB
            DocumentListView(viewModel: documentListVM)
                .tabItem {
                    Label("Documents", systemImage: "doc.text.fill")
                }
                .tag(Tab.documents)

            // COMPOSE TAB
            ComposeView(
                viewModel: ComposeViewModel(),
                onSave: {
                    documentListVM.loadDocuments()
                }
            )
            .tabItem {
                Label("Compose", systemImage: "square.and.pencil")
            }
            .tag(Tab.compose)

            // SETTINGS TAB
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { _, _ in
            animateTab.toggle()
            HapticManager.shared.toolbarTap()
        }
    }
}
