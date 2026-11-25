import SwiftUI

struct ProductGrid: View {
    let products: [Product]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: Theme.tileMinWidth), spacing: Theme.Spacing.m)],
            spacing: Theme.Spacing.m
        ) {
            ForEach(products) { product in
                NavigationLink(value: Route.product(product)) {
                    ProductTile(product: product)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
