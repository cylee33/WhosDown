import SwiftUI

/// A form field as on H02/H41: small label above a white rounded box, optional hint or error below.
struct LabeledField<Content: View>: View {
    let label: String
    var hint: String?
    var error: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
            content
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: 48)
                .background(Color.surface, in: .rect(cornerRadius: Radius.button))
                .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(error == nil ? Color.border : Color.destructive))
            if let error {
                Text(error).font(.footnote).foregroundStyle(Color.destructive)
            } else if let hint {
                Text(hint).font(.footnote).foregroundStyle(Color.textSecondary)
            }
        }
    }
}

/// Primary button that shows a spinner and ignores taps while `isWorking` (1.2 rule 6, 1.26 rule 5).
struct WorkingButton: View {
    let title: String
    let isWorking: Bool
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isWorking { ProgressView().tint(.white) } else { Text(title) }
        }
        .buttonStyle(.primary)
        .disabled(isWorking || !isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

#Preview {
    VStack(spacing: Spacing.s) {
        LabeledField(label: "Email") { TextField("you@example.com", text: .constant("")) }
        LabeledField(label: "Password", hint: "At least 8 characters.") { SecureField("", text: .constant("")) }
        LabeledField(label: "Display name", error: "Enter a name.") { TextField("", text: .constant("")) }
        WorkingButton(title: "Continue", isWorking: false) {}
        WorkingButton(title: "Continue", isWorking: true) {}
    }
    .padding(Spacing.m)
    .background(Color.background)
}
