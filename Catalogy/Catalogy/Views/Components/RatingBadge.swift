import SwiftUI

struct RatingBadge: View {
    let rating: Product.Rating
    var showsCount = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill").foregroundStyle(Theme.Palette.rating)
            Text(rating.average, format: .number.precision(.fractionLength(1)))
                .fontWeight(.semibold)
            if showsCount {
                Text("(\(rating.count))").foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(rating.average, specifier: "%.1f") out of 5 from \(rating.count) reviews")
    }
}
