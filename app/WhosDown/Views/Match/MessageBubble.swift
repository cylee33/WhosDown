import SwiftUI

/// One chat message (1.20). Yours on the right, everyone else on the left. The Host gets a label.
struct MessageBubble: View {
    let message: Message
    let isMine: Bool
    let isHost: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: Spacing.xl) }
            if !isMine {
                Text(initials)
                    .font(.caption2.weight(.bold)).foregroundStyle(Color.brand)
                    .frame(width: 32, height: 32)
                    .background(Color.brandSoft, in: .circle)
            }
            VStack(alignment: isMine ? .trailing : .leading, spacing: Spacing.xxs) {
                if isHost {
                    Text("Host").font(.caption2.weight(.bold)).foregroundStyle(Color.brand)
                }
                Text(message.text)
                    .foregroundStyle(isMine ? Color.onBrand : Color.textPrimary)
                    .padding(Spacing.xs)
                    .background(isMine ? Color.brand : Color.surface, in: .rect(cornerRadius: Radius.button))
                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).foregroundStyle(Color.textSecondary)
            }
            if !isMine { Spacer(minLength: Spacing.xl) }
        }
    }

    private var initials: String {
        message.senderName.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined()
    }
}
