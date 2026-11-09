import SwiftUI

/// H12 Join review (1.14). Opens as a bottom sheet.
struct JoinReviewSheet: View {
    let match: Match
    @Binding var note: String
    var isWorking: Bool
    var errorMessage: String? = nil
    var onSend: () -> Void
    var onClose: () -> Void

    var body: some View {
        SheetContainer(
            title: "Request to join", message: "\(match.title) · \(MatchFormatting.when(match)) · \(match.venueName)",
            primaryTitle: isWorking ? "Sending…" : "Send join request", primaryAction: onSend,
            secondaryTitle: "Close", secondaryAction: onClose
        ) {
            Text(match.priceCents == 0 ? "This Match is free. You won't be charged." : "Price \(MatchFormatting.price(match)). Display only.")
                .font(.subheadline).foregroundStyle(Color.textPrimary)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("1. You send a request").font(.footnote)
                Text("2. The Host approves or declines").font(.footnote)
                Text("3. You'll see the result here").font(.footnote)
            }
            .foregroundStyle(Color.textSecondary)
            .card()

            TextField("Note to Host (optional)", text: $note, axis: .vertical)
                .lineLimit(3...5)
                .onChange(of: note) { _, newValue in
                    if newValue.count > JoinRules.noteLimit {
                        note = String(newValue.prefix(JoinRules.noteLimit))
                    }
                }
            Text("\(note.count)/\(JoinRules.noteLimit)")
                .font(.caption).foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let errorMessage { Text(errorMessage).foregroundStyle(Color.destructive) }
            if isWorking { ProgressView() }
        }
        .disabled(isWorking)
        .interactiveDismissDisabled(isWorking)
    }
}
