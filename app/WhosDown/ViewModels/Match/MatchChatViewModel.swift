import Foundation

/// H16 Match chat (1.20).
@Observable
final class MatchChatViewModel {
    private(set) var messages: [Message] = []
    private(set) var older: [Message] = []
    var draft = ""
    var errorMessage: String?
    private(set) var isSending = false

    let matchId: String
    let senderId: String
    let senderName: String
    private let chat: ChatRepository

    init(matchId: String, senderId: String, senderName: String, chat: ChatRepository) {
        self.matchId = matchId
        self.senderId = senderId
        self.senderName = senderName
        self.chat = chat
    }

    var visible: [Message] { older + messages }

    func start() async {
        do {
            for try await value in chat.messageChanges(matchId: matchId) {
                messages = value
            }
        } catch {
            errorMessage = "Couldn't load Match chat."
        }
    }

    func loadOlder() async {
        guard let earliest = visible.first?.sentAt else { return }
        do {
            let page = try await chat.olderMessages(matchId: matchId, before: earliest)
            let known = Set(visible.compactMap(\.id))
            older.insert(contentsOf: page.filter { !known.contains($0.id ?? "") }, at: 0)
        } catch {
            errorMessage = "Couldn't load older messages."
        }
    }

    func send() async {
        let text = draft
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            try await chat.send(matchId: matchId, senderId: senderId, senderName: senderName, text: text)
            draft = ""
        } catch {
            errorMessage = "Couldn't send that message."
        }
    }
}
