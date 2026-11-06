import SwiftUI

/// H12 Join review (1.14). Opens as a bottom sheet.
struct JoinReviewSheet: View {
    let match: Match
    @Binding var note: String
    var isWorking: Bool
    var onSend: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Request to join").font(.title2.bold()).foregroundStyle(Color.textPrimary)
            Text("\(match.title) · \(MatchFormatting.when(match)) · \(match.venueName)")
                .font(.subheadline).foregroundStyle(Color.textSecondary)
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

            Button(action: onSend) {
                if isWorking { ProgressView().tint(.white) } else { Text("Send join request") }
            }
            .buttonStyle(.primary)
            .disabled(isWorking)
            Button("Close", action: onClose).buttonStyle(.secondary)
        }
        .padding(Spacing.m)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
