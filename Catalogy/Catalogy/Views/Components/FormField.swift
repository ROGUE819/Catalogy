import SwiftUI

/// Labelled text field with inline validation, used by the enquiry form.
struct FormField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var error: String?
    var showsError = false
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            HStack(alignment: axis == .vertical ? .top : .center, spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .padding(.top, axis == .vertical ? 2 : 0)
                TextField(title, text: $text, axis: axis)
                    .lineLimit(axis == .vertical ? 4...8 : 1...1)
            }
            .padding(14)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)
                    .strokeBorder(showsError && error != nil ? Color.red.opacity(0.7) : .clear, lineWidth: 1)
            }
            if showsError, let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }
}
