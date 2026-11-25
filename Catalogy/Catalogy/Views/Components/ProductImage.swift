import SwiftUI

/// Product image on a white card (product shots are on white backgrounds),
/// with a shimmer while loading and a fallback icon on failure.
struct ProductImage: View {
    let url: URL
    var padding: CGFloat = Theme.Spacing.m

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit().padding(padding)
            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            default:
                Rectangle().fill(.quaternary).shimmering()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.imageBackground)
        .accessibilityHidden(true)
    }
}
