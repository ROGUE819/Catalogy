import SwiftUI

struct CategoryChip: View {
    let category: Category

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: category.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Palette.accent)
                .frame(width: 32, height: 32)
                .background(Theme.Palette.accent.opacity(0.12), in: Circle())
            Text(category.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(Theme.Palette.surface, in: Capsule())
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}
