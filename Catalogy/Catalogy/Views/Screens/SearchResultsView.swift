import SwiftUI

struct SearchResultsView: View {
    let viewModel: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            LoadableView(state: viewModel.results, retry: viewModel.search) {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            } content: { products in
                SectionHeader(
                    title: "Results for “\(viewModel.lastSearchedTerm)”",
                    subtitle: products.count == 1 ? "1 product" : "\(products.count) products"
                )
                if products.isEmpty {
                    ContentUnavailableView.search(text: viewModel.lastSearchedTerm)
                } else {
                    ProductGrid(products: products)
                }
            }
        }
    }
}
