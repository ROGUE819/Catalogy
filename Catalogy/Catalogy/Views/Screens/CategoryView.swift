import SwiftUI

struct CategoryView: View {
    @State private var viewModel: CategoryViewModel

    init(category: Category, api: CatalogAPI) {
        _viewModel = State(initialValue: CategoryViewModel(category: category, api: api))
    }

    var body: some View {
        ScrollView {
            LoadableView(state: viewModel.state, retry: viewModel.load) {
                ProgressView().frame(maxWidth: .infinity, minHeight: 300)
            } content: { page in
                VStack(spacing: Theme.Spacing.xl) {
                    VStack(spacing: Theme.Spacing.m) {
                        SectionHeader(title: "Top rated", subtitle: "Best reviewed in \(page.category.name)")
                        ProductGrid(products: page.topRated)
                    }
                    if !page.others.isEmpty {
                        VStack(spacing: Theme.Spacing.m) {
                            SectionHeader(title: "More in \(page.category.name)")
                            ProductGrid(products: page.others)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.Palette.background)
        .navigationTitle(viewModel.category.name)
        .task { if viewModel.state.value == nil { await viewModel.load() } }
        .refreshable { await viewModel.load() }
    }
}
