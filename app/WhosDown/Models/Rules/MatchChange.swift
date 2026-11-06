import Foundation

/// Which Host edits are worth a notification (1.18). Description-only edits are not.
enum MatchChange {
    static func changes(from match: Match, edits: MatchEdits) -> [AppNotification.Change] {
        var changes: [AppNotification.Change] = []
        if match.startTime != edits.startTime || match.endTime != edits.endTime {
            changes.append(.init(field: "Time", oldValue: MatchFormatting.dateRange(match), newValue: range(edits)))
        }
        if let venue = edits.venue, venue.name != match.venueName {
            changes.append(.init(field: "Location", oldValue: match.venueName, newValue: venue.name))
        }
        if match.playerLimit != edits.playerLimit {
            changes.append(.init(field: "Player limit", oldValue: "\(match.playerLimit)", newValue: "\(edits.playerLimit)"))
        }
        if match.joinType != edits.joinType {
            changes.append(.init(
                field: "Join type",
                oldValue: match.joinType == .open ? "Open" : "Approval required",
                newValue: edits.joinType == .open ? "Open" : "Approval required"
            ))
        }
        let oldNotes = match.notes ?? ""
        let newNotes = edits.notes ?? ""
        if oldNotes != newNotes {
            changes.append(.init(field: "Description", oldValue: oldNotes, newValue: newNotes))
        }
        return changes
    }

    private static func range(_ edits: MatchEdits) -> String {
        "\(edits.startTime.formatted(date: .abbreviated, time: .shortened))–\(edits.endTime.formatted(date: .omitted, time: .shortened))"
    }
}
