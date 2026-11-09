import SwiftUI

/// H37 Leave confirmation (1.16).
struct LeaveSheet: View {
    var isWorking: Bool
    var errorMessage: String? = nil
    var onLeave: () -> Void
    var onKeep: () -> Void

    var body: some View {
        SheetContainer(
            title: "Leave this Match?",
            message: "Your spot will immediately reopen for another Player.",
            primaryTitle: "Leave Match",
            isDestructive: true,
            primaryAction: onLeave,
            secondaryTitle: "Keep my spot",
            secondaryAction: onKeep
        ) {
            if let errorMessage { Text(errorMessage).foregroundStyle(Color.destructive) }
            Text("You can rejoin later only if a spot is still available.")
                .font(.footnote).foregroundStyle(Color.destructive)
        }
        .overlay { if isWorking { ProgressView() } }
        .interactiveDismissDisabled(isWorking)
        .disabled(isWorking)
    }
}

/// Cancel-request confirmation (1.16). Same layout as H37.
struct CancelRequestSheet: View {
    var isWorking: Bool
    var errorMessage: String? = nil
    var onCancel: () -> Void
    var onKeep: () -> Void

    var body: some View {
        SheetContainer(
            title: "Cancel your request?",
            message: "The Host won't see it anymore.",
            primaryTitle: "Cancel request",
            isDestructive: true,
            primaryAction: onCancel,
            secondaryTitle: "Keep request",
            secondaryAction: onKeep
        ) {
            if let errorMessage { Text(errorMessage).foregroundStyle(Color.destructive) }
        }
        .overlay { if isWorking { ProgressView() } }
        .interactiveDismissDisabled(isWorking)
        .disabled(isWorking)
    }
}
