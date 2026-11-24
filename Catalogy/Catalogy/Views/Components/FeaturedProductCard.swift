import SwiftUI

/// Larger card for the home page's featured carousel.
struct FeaturedProductCard: View {
    let product: Product
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProductImage(url: product.imageUrl, padding: Theme.Spacing.l)
                .frame(height: 200)
                .overlay(alignment: .topLeading) {
                    Text("#\(rank)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Palette.accent, in: Capsule())
                        .padding(Theme.Spacing.m - 4)
                }

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(product.category.name.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(product.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                HStack {
                    Text(product.formattedPrice).font(.title3.weight(.bold))
                    Spacer(minLength: 0)
                    RatingBadge(rating: product.rating)
                }
            }
            .padding(Theme.Spacing.m)
        }
        .frame(width: Theme.featuredCardWidth)
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("productTile_\(product.id)")
    }
}
