import SwiftUI

/// Grid tile used on category and search pages.
struct ProductTile: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProductImage(url: product.imageUrl)
                .frame(height: 150)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(product.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                HStack {
                    Text(product.formattedPrice).font(.headline)
                    Spacer(minLength: 0)
                    RatingBadge(rating: product.rating)
                }
            }
            .padding(Theme.Spacing.m - 4)
        }
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("productTile_\(product.id)")
    }
}
