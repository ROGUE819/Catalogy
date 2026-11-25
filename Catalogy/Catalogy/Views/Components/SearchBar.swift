import SwiftUI

/// Search field with an explicit Search button (per the acceptance criteria).
struct SearchBar: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search products", text: $viewModel.term)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(runSearch)
                    .accessibilityIdentifier("searchField")
                if !viewModel.term.isEmpty {
                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

            Button("Search", action: runSearch)
                .font(.subheadline.weight(.semibold))
                .frame(height: 48)
                .padding(.horizontal, Theme.Spacing.m)
                .background(viewModel.canSearch ? Theme.Palette.accent : Color.gray.opacity(0.3),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
                .foregroundStyle(.white)
                .disabled(!viewModel.canSearch)
                .accessibilityIdentifier("searchButton")
        }
        .animation(.easeOut(duration: 0.15), value: viewModel.canSearch)
    }

    private func runSearch() {
        isFocused = false
        Task { await viewModel.search() }
    }
}
