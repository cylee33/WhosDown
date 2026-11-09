import EventKit
import Foundation

/// Uses the system editor, which grants access only to the event the Player saves.
enum CalendarEventBuilder {
    static func canAdd(_ match: Match, userId: String?, approved: Bool, now: Date = .now) -> Bool {
        userId != nil && match.status == .scheduled && match.startTime > now
            && (match.hostId == userId || approved)
    }

    static func event(for match: Match, address: String?, store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = "\(match.title) · WhosDown"
        event.startDate = match.startTime
        event.endDate = match.endTime
        event.location = [match.venueName, address].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        event.notes = match.notes
        return event
    }
}
