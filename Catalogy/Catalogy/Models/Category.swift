import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let name: String

    /// SF Symbol for known categories; unknown ones get a generic tag icon.
    var symbolName: String {
        switch id {
        case "electronics": "desktopcomputer"
        case "jewelery": "sparkles"
        case "mens-clothing": "tshirt"
        case "womens-clothing": "handbag"
        default: "tag"
        }
    }
}
