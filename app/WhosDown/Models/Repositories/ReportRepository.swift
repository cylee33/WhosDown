import FirebaseFirestore
import Foundation

protocol ReportRepository {
    func submit(reporterId: String, reportedUserId: String?, matchId: String?, reason: Report.Reason, details: String?) async throws
}

final class FirebaseReportRepository: ReportRepository {
    func submit(reporterId: String, reportedUserId: String?, matchId: String?, reason: Report.Reason, details: String?) async throws {
        try await Firestore.firestore().collection("reports").addDocument(data: [
            "reporterId": reporterId,
            "reportedUserId": reportedUserId ?? NSNull(),
            "matchId": matchId ?? NSNull(),
            "reason": reason.rawValue,
            "details": details ?? NSNull(),
            "status": "open",
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }
}

final class FakeReportRepository: ReportRepository {
    private(set) var submissions: [Report] = []
    var shouldFail = false
    func submit(reporterId: String, reportedUserId: String?, matchId: String?, reason: Report.Reason, details: String?) async throws {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        submissions.append(Report(reporterId: reporterId, reportedUserId: reportedUserId, matchId: matchId,
                                  reason: reason, details: details, status: "open", createdAt: .now))
    }
}
