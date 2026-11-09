import Foundation

@Observable
final class NotificationsViewModel {
    private(set) var items: [AppNotification] = []
    private(set) var isWorking = false
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    let userId: String
    private let repository: NotificationRepository

    init(userId: String, repository: NotificationRepository) {
        self.userId = userId
        self.repository = repository
    }

    func start() async {
        do {
            for try await value in repository.inbox(userId: userId) { items = value; isLoading = false }
        } catch {
            isLoading = false
            if !Task.isCancelled { errorMessage = "Couldn't load notifications. Please try again." }
        }
    }

    func markRead(_ id: String) async { await perform { try await self.repository.markRead(userId: self.userId, notificationId: id) } }
    func markAll() async { await perform { try await self.repository.markAllRead(userId: self.userId, ids: self.items.compactMap(\.id)) } }
    func delete(_ ids: [String]) async {
        await perform { for id in ids { try await self.repository.delete(userId: self.userId, notificationId: id) } }
    }

    private func perform(_ action: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do { try await action() }
        catch { errorMessage = "Couldn't update notifications. Please try again." }
    }
}
