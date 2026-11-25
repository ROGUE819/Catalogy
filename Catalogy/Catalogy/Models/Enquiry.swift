import Foundation

/// Request and response for submitting a product enquiry.
struct EnquiryRequest: Codable, Equatable {
    var productId: String
    var name: String
    var email: String
    var phone: String?
    var message: String?
}

struct EnquiryConfirmation: Codable, Equatable {
    let id: String
    let message: String
}
