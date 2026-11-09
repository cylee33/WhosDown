import EventKit
import EventKitUI
import SwiftUI

struct CalendarSheet: UIViewControllerRepresentable {
    let match: Match
    let address: String?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let editor = EKEventEditViewController()
        let store = EKEventStore()
        editor.eventStore = store
        editor.event = CalendarEventBuilder.event(for: match, address: address, store: store)
        editor.editViewDelegate = context.coordinator
        return editor
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let close: () -> Void
        init(close: @escaping () -> Void) { self.close = close }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            close()
        }
    }
}
