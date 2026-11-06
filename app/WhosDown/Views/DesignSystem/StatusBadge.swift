import SwiftUI

/// One color per RSVP status, used everywhere (1.14).
struct StatusBadge: View {
    let title: String
    var foreground: Color
    var background: Color

    init(status: RSVPStatus) {
        switch status {
        case .pending:
            title = "PENDING"
            foreground = .statusPending
            background = .statusPendingSoft
        case .approved:
            title = "APPROVED"
            foreground = .statusApproved
            background = .statusApprovedSoft
        case .declined:
            title = "DECLINED"
            foreground = .statusDeclined
            background = .statusDeclinedSoft
        case .waitlisted:
            title = "WAITLIST"
            foreground = .statusWaitlisted
            background = .statusWaitlistedSoft
        case .left:
            title = "LEFT"
            foreground = .textSecondary
            background = .border.opacity(0.5)
        }
    }

    init(title: String, foreground: Color, background: Color) {
        self.title = title
        self.foreground = foreground
        self.background = background
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(background, in: .rect(cornerRadius: Radius.chip))
    }
}
