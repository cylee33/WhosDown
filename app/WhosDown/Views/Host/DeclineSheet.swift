import SwiftUI

/// Decline message sheet (1.15). Built from H37's layout.
struct DeclineSheet: View {
    let name: String
    @Binding var message: String
    var isWorking: Bool
    var onDecline: () -> Void
    var onKeep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Decline \(name)'s request?").font(.title2.bold()).foregroundStyle(Color.textPrimary)
            Text("They'll see your message on their request.").font(.subheadline).foregroundStyle(Color.textSecondary)
            TextField("Message (optional)", text: $message, axis: .vertical)
                .lineLimit(2...4)
                .onChange(of: message) { _, newValue in
                    if newValue.count > JoinRules.noteLimit {
                        message = String(newValue.prefix(JoinRules.noteLimit))
                    }
                }
            Text("\(message.count)/\(JoinRules.noteLimit)")
                .font(.caption).foregroundStyle(Color.textSecondary)
            Button(action: onDecline) {
                if isWorking { ProgressView().tint(.white) } else { Text("Decline") }
            }
            .buttonStyle(.destructive)
            .disabled(isWorking)
            Button("Keep request", action: onKeep).buttonStyle(.secondary)
        }
        .padding(Spacing.m)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
