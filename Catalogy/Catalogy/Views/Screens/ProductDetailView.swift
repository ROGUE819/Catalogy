import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    @State private var showingEnquiry = false
    private let api: CatalogAPI

    init(product: Product, api: CatalogAPI) {
        self.api = api
        _viewModel = State(initialValue: ProductDetailViewModel(product: product, api: api))
    }

    private var product: Product { viewModel.product }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ProductImage(url: product.imageUrl, padding: Theme.Spacing.xl)
                    .frame(height: 340)

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Label(product.category.name, systemImage: product.category.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Palette.accent.opacity(0.12), in: Capsule())

                    Text(product.title)
                        .font(.title2.weight(.bold))

                    HStack(alignment: .firstTextBaseline) {
                        Text(product.formattedPrice)
                            .font(.title.weight(.heavy))
                        Spacer()
                        RatingBadge(rating: product.rating, showsCount: true)
                            .font(.subheadline)
                    }

                    Divider()

                    Text("About this product").font(.headline)
                    Text(product.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(Theme.Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Palette.surface)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.l, topTrailingRadius: Theme.Radius.l))
                .offset(y: -Theme.Spacing.l)
                .padding(.bottom, -Theme.Spacing.l)
            }
        }
        .background(Theme.Palette.surface)
        .safeAreaInset(edge: .bottom) { enquireBar }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEnquiry) {
            EnquiryFormView(product: product, api: api)
        }
        .task { await viewModel.refresh() }
    }

    private var enquireBar: some View {
        Button {
            showingEnquiry = true
        } label: {
            Label("Enquire about this product", systemImage: "envelope.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.m))
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s + 2)
        .background(.bar)
        .accessibilityIdentifier("enquireButton")
    }
}
