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
    static let maxMessageLength = 2000

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Name is required" }
        if trimmed.count > 100 { return "Name must be 100 characters or fewer" }
        return nil
    }

    var emailError: String? {
        Self.isValidEmail(email) ? nil : "Enter a valid email address"
    }

    var phoneError: String? {
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        if trimmed.count > 30 || trimmed.wholeMatch(of: /[+0-9 ()\-]+/) == nil {
            return "Use digits, spaces and + ( ) - only"
        }
        return nil
    }

    var messageError: String? {
        message.count > Self.maxMessageLength ? "Message must be \(Self.maxMessageLength) characters or fewer" : nil
    }

    var canSubmit: Bool {
        nameError == nil && emailError == nil && phoneError == nil && messageError == nil
            && status != .submitting && !isSubmitted
    }

    private var isSubmitted: Bool {
        if case .submitted = status { true } else { false }
    }

    func submit() async {
        guard canSubmit else { return }
        status = .submitting
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = EnquiryRequest(
            productId: product.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            message: trimmedMessage.isEmpty ? nil : trimmedMessage
        )
        do {
            let confirmation = try await api.submitEnquiry(request)
            status = .submitted(confirmation.message)
        } catch {
            status = .failed((error as? LocalizedError)?.errorDescription ?? "Something went wrong.")
        }
    }

    static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= 254 && trimmed.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }
}
