import Foundation
import FirebaseCore
import FirebaseFirestore

struct CollectionResult: Identifiable {
  let id = UUID()
  let path: String
  let rows: [String]
  let error: String?
}

enum FirestoreService {
  static var isConfigured: Bool { FirebaseApp.app() != nil }

  // Writes every SeedData document in one batch.
  static func seed() async throws {
    let db = Firestore.firestore()
    let batch = db.batch()
    for doc in SeedData.documents {
      batch.setData(doc.data, forDocument: db.document(doc.path))
    }
    try await batch.commit()
  }

  // Reads each collection back from Firestore and decodes it with data(as:).
  static func loadAll() async -> [CollectionResult] {
    [
      await load("users", AppUser.self) { "\($0.id ?? "?") · \($0.displayName) · \(Int(($0.stats.reliability ?? 0) * 100))%" },
      await loadDocument("users/u_alex/private/settings", UserSettings.self) { "radius \($0.searchRadiusMiles) mi · favorites \($0.favoriteVenueIds.count)" },
      await load("users/u_alex/friends", Friendship.self) { "\($0.id ?? "?") · \($0.displayName) · \($0.status.rawValue)" },
      await load("users/u_alex/notifications", AppNotification.self) { "\($0.id ?? "?") · \($0.type.rawValue) · \($0.title)" },
      await load("venues", Venue.self) { "\($0.id ?? "?") · \($0.name)" },
      await load("games", Game.self) { "\($0.id ?? "?") · \($0.title) · \($0.joinedCount)/\($0.playerLimit)" },
      await load("games/gm_7d2k/rsvps", RSVP.self) { "\($0.id ?? "?") · \($0.displayName) · \($0.status.rawValue)" },
      await load("groups", PlayGroup.self) { "\($0.id ?? "?") · \($0.name) · \($0.memberCount)" },
      await load("groups/g_westside/members", GroupMember.self) { "\($0.id ?? "?") · \($0.role.rawValue)" },
      await load("conversations", Conversation.self) { "\($0.id ?? "?") · \($0.type.rawValue) · \($0.title)" },
      await load("conversations/c_gm_7d2k/messages", Message.self) { "\($0.senderName): \($0.text)" },
      await load("reviews", Review.self) { "\($0.id ?? "?") · MVP \($0.isMVP) · \($0.tags.count) tags" },
      await load("reports", Report.self) { "\($0.id ?? "?") · \($0.reason.rawValue) · \($0.status.rawValue)" }
    ]
  }

  private static func load<T: Decodable>(_ path: String, _ type: T.Type, describe: (T) -> String) async -> CollectionResult {
    do {
      let snapshot = try await Firestore.firestore().collection(path).getDocuments()
      let rows = try snapshot.documents.map { describe(try $0.data(as: T.self)) }
      return CollectionResult(path: path, rows: rows, error: nil)
    } catch {
      return CollectionResult(path: path, rows: [], error: error.localizedDescription)
    }
  }

  private static func loadDocument<T: Decodable>(_ path: String, _ type: T.Type, describe: (T) -> String) async -> CollectionResult {
    do {
      let snapshot = try await Firestore.firestore().document(path).getDocument()
      return CollectionResult(path: path, rows: [describe(try snapshot.data(as: T.self))], error: nil)
    } catch {
      return CollectionResult(path: path, rows: [], error: error.localizedDescription)
    }
  }
}
