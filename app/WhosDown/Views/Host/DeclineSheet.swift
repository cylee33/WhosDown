import SwiftUI

/// Decline message sheet (1.15). Built from H37's layout.
struct DeclineSheet: View {
    let name: String
    @Binding var message: String
    var isWorking: Bool
    var errorMessage: String? = nil
    var onDecline: () -> Void
    var onKeep: () -> Void

    var body: some View {
        SheetContainer(
            title: "Decline \(name)'s request?", message: "They'll see your message on their request.",
            primaryTitle: isWorking ? "Declining…" : "Decline", isDestructive: true,
            primaryAction: onDecline, secondaryTitle: "Keep request", secondaryAction: onKeep
        ) {
            TextField("Message (optional)", text: $message, axis: .vertical)
                .lineLimit(2...4)
                .onChange(of: message) { _, newValue in
                    if newValue.count > JoinRules.noteLimit {
                        message = String(newValue.prefix(JoinRules.noteLimit))
                    }
                }
            Text("\(message.count)/\(JoinRules.noteLimit)")
                .font(.caption).foregroundStyle(Color.textSecondary)
            if let errorMessage { Text(errorMessage).foregroundStyle(Color.destructive) }
            if isWorking { ProgressView() }
        }
        .disabled(isWorking)
        .interactiveDismissDisabled(isWorking)
    }
}
