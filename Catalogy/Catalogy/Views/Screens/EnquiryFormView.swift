import SwiftUI

struct EnquiryFormView: View {
    @State private var viewModel: EnquiryViewModel
    @State private var attemptedSubmit = false
    @Environment(\.dismiss) private var dismiss

    init(product: Product, api: CatalogAPI) {
        _viewModel = State(initialValue: EnquiryViewModel(product: product, api: api))
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .submitted(let message) = viewModel.status {
                    ThankYouView(message: message) { dismiss() }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else {
                    form
                }
            }
            .animation(.spring(duration: 0.4), value: viewModel.status)
            .background(Theme.Palette.background)
            .navigationTitle("Enquire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                productSummary

                VStack(spacing: Theme.Spacing.m) {
                    FormField(title: "Name", systemImage: "person", text: $viewModel.name,
                              error: viewModel.nameError, showsError: attemptedSubmit)
                        .textContentType(.name)
                        .accessibilityIdentifier("nameField")
                    FormField(title: "Email", systemImage: "envelope", text: $viewModel.email,
                              error: viewModel.emailError, showsError: attemptedSubmit)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("emailField")
                    FormField(title: "Phone (optional)", systemImage: "phone", text: $viewModel.phone,
                              error: viewModel.phoneError, showsError: !viewModel.phone.isEmpty)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    FormField(title: "Message (optional)", systemImage: "text.bubble",
                              text: $viewModel.message, error: viewModel.messageError,
                              showsError: viewModel.messageError != nil, axis: .vertical)
                }

                if case .failed(let message) = viewModel.status {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.Radius.s))
                }

                submitButton
            }
            .padding(Theme.Spacing.m)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var productSummary: some View {
        HStack(spacing: Theme.Spacing.m - 4) {
            ProductImage(url: viewModel.product.imageUrl, padding: 6)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(viewModel.product.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                Text(viewModel.product.formattedPrice).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.m - 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private var submitButton: some View {
        Button {
            attemptedSubmit = true
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.status == .submitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Send enquiry").font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.m))
        .disabled(viewModel.status == .submitting)
        .accessibilityIdentifier("submitEnquiryButton")
    }
}
