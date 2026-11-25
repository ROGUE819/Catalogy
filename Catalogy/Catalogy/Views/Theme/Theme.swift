import SwiftUI

/// Single place for brand styling, so the look and feel can be swapped once the
/// creative work lands without touching individual screens.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 24
    }

    enum Palette {
        static let accent = Color.accentColor
        static let rating = Color.orange
        static let surface = Color(.secondarySystemGroupedBackground)
        static let background = Color(.systemGroupedBackground)
        static let imageBackground = Color.white
    }

    static let tileMinWidth: CGFloat = 158
    static let featuredCardWidth: CGFloat = 220
}
