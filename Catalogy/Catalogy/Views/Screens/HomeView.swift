import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var path: [Route] = []
    private let api: CatalogAPI

    init(api: CatalogAPI) {
        self.api = api
        _viewModel = State(initialValue: HomeViewModel(api: api))
        _searchViewModel = State(initialValue: SearchViewModel(api: api))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    SearchBar(viewModel: searchViewModel)
                        .padding(.horizontal, Theme.Spacing.m)

                    if searchViewModel.isShowingResults {
                        SearchResultsView(viewModel: searchViewModel)
                            .padding(.horizontal, Theme.Spacing.m)
                    } else {
                        categoriesSection
                        featuredSection
                    }
                }
                .padding(.vertical, Theme.Spacing.m)
                .animation(.easeInOut(duration: 0.2), value: searchViewModel.isShowingResults)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Palette.background)
            .navigationTitle("Catalogy")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .category(let category): CategoryView(category: category, api: api)
                case .product(let product): ProductDetailView(product: product, api: api)
                }
            }
            .task { if viewModel.featured.value == nil { await viewModel.load() } }
            .refreshable { await viewModel.load() }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m - 4) {
            SectionHeader(title: "Shop by category").padding(.horizontal, Theme.Spacing.m)
            LoadableView(state: viewModel.categories, retry: viewModel.load) {
                ProgressView().frame(maxWidth: .infinity, minHeight: 44)
            } content: { categories in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.s + 2) {
                        ForEach(categories) { category in
                            NavigationLink(value: Route.category(category)) {
                                CategoryChip(category: category)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("category_\(category.id)")
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m - 4) {
            SectionHeader(title: "Top rated", subtitle: "Hand-picked favourites")
                .padding(.horizontal, Theme.Spacing.m)
            LoadableView(state: viewModel.featured, retry: viewModel.load) {
                ProgressView().frame(maxWidth: .infinity, minHeight: 320)
            } content: { products in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Theme.Spacing.m) {
                        ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                            NavigationLink(value: Route.product(product)) {
                                FeaturedProductCard(product: product, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

#Preview {
    HomeView(api: HTTPCatalogAPI.fromEnvironment())
}
