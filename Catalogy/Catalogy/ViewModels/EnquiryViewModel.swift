import Foundation

@Observable
final class EnquiryViewModel {
    enum Status: Equatable {
        case editing
        case submitting
        case submitted(String)
        case failed(String)
    }

    var name = ""
    var email = ""
    var phone = ""
    var message = ""
    private(set) var status: Status = .editing
    let product: Product
    private let api: CatalogAPI

    init(product: Product, api: CatalogAPI) {
        self.product = product
        self.api = api
    }

    // Client-side checks mirror the backend's; the backend remains authoritative.
    var nameError: String? {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "Name is required" : nil
    }

    var emailError: String? {
        Self.isValidEmail(email) ? nil : "Enter a valid email address"
    }

    var canSubmit: Bool { nameError == nil && emailError == nil && status != .submitting }

    func submit() async {
        guard canSubmit else { return }
        status = .submitting
        let request = EnquiryRequest(
            productId: product.id,
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            phone: phone.isEmpty ? nil : phone,
            message: message.isEmpty ? nil : message
        )
        do {
            let confirmation = try await api.submitEnquiry(request)
            status = .submitted(confirmation.message)
        } catch {
            status = .failed((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
        }
    }

    static func isValidEmail(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespaces)
            .wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }
}
