import FirebaseFirestore
import Foundation
import Testing
@testable import WhosDown

/// Data models decode the document shapes the seed script and security rules use (architecture §2).
struct ModelTests {
    private func matchData(joinedCount: Int = 12, sport: String = "soccer", customSportName: Any = NSNull()) -> [String: Any] {
        let start = Timestamp(date: Date(timeIntervalSince1970: 1_800_000_000))
        return [
            "title": "Pickup Soccer", "titleLowercase": "pickup soccer", "sport": sport, "customSportName": customSportName,
            "notes": "Bring a light + dark shirt.", "hostId": "seed_jamie", "hostName": "Jamie Morales",
            "venueId": "v_cmu_soccer", "venueName": "CMU Soccer Field",
            "location": ["latitude": 40.4433, "longitude": -79.9436], "geohash": "dppnhf",
            "isIndoor": false, "surface": "turf", "hasLights": true,
            "startTime": start, "endTime": Timestamp(seconds: start.seconds + 5400, nanoseconds: 0),
            "skillLevel": "allLevels", "joinType": "approvalRequired", "priceCents": 0, "playerLimit": 14,
            "waitlistEnabled": true, "joinedCount": joinedCount, "pendingCount": 1, "waitlistCount": 0, "waitlistIds": [String](),
            "attendeePreview": ["JM", "AM"], "fieldReserved": true, "reservationWindow": "6:45–8:45 PM", "facilityNote": NSNull(),
            "status": "scheduled", "cancelReason": NSNull(), "checkedInAt": NSNull(), "createdAt": start, "updatedAt": start,
        ]
    }

    @Test func matchDecodesFromFirestoreData() throws {
        let match = try Firestore.Decoder().decode(Match.self, from: matchData())
        #expect(match.title == "Pickup Soccer")
        #expect(match.joinType == .approvalRequired)
        #expect(match.skillLevel == .allLevels)
        #expect(match.endTime.timeIntervalSince(match.startTime) == 5400)
        #expect(match.location.latitude == 40.4433)
        #expect(match.checkedInAt == nil)
    }

    @Test func spotsLeftAndFull() throws {
        let open = try Firestore.Decoder().decode(Match.self, from: matchData(joinedCount: 12))
        #expect(open.spotsLeft == 2)
        #expect(!open.isFull)
        let full = try Firestore.Decoder().decode(Match.self, from: matchData(joinedCount: 14))
        #expect(full.spotsLeft == 0)
        #expect(full.isFull)
    }

    @Test func customSportNameIsShownForOther() throws {
        let match = try Firestore.Decoder().decode(Match.self, from: matchData(sport: "other", customSportName: "Spikeball"))
        #expect(match.sportName == "Spikeball")
    }

    @Test func rsvpDecodesWithCheckInFields() throws {
        let rsvp = try Firestore.Decoder().decode(RSVP.self, from: [
            "userId": "seed_alex", "displayName": "Alex Morgan", "skillLevel": "allLevels", "status": "approved",
            "isHost": false, "noteToHost": NSNull(), "hostResponse": NSNull(),
            "requestedAt": Timestamp(date: .now), "respondedAt": Timestamp(date: .now),
            "checkedIn": true, "attended": false,
        ])
        #expect(rsvp.status == .approved)
        #expect(rsvp.checkedIn)
        #expect(rsvp.attended == false)
    }

    @Test func initialsUseFirstTwoWords() {
        let profile = UserProfile(
            displayName: "Alex Morgan", displayNameLowercase: "alex morgan", playStyles: [], sportLevels: [:], createdAt: .now
        )
        #expect(profile.initials == "AM")
    }
}
