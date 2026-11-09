import Foundation

@Observable
final class ReportViewModel {
    var reason: Report.Reason?
    var details = ""
    private(set) var isWorking = false
    private(set) var submitted = false
    private(set) var errorMessage: String?
    let reporterId: String
    let reportedUserId: String?
    let matchId: String?
    private let reports: ReportRepository

    init(reporterId: String, reportedUserId: String?, matchId: String?, reports: ReportRepository) {
        self.reporterId = reporterId
        self.reportedUserId = reportedUserId
        self.matchId = matchId
        self.reports = reports
    }

    var canSubmit: Bool {
        reason != nil && details.count <= 1000 && !reporterId.isEmpty && reportedUserId != reporterId
            && (reportedUserId != nil || matchId != nil) && !isWorking && !submitted
    }

    func submit() async {
        guard canSubmit, let reason else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await reports.submit(reporterId: reporterId, reportedUserId: reportedUserId, matchId: matchId,
                                     reason: reason, details: ProfileRules.trimmedOrNil(details))
            submitted = true
        } catch {
            errorMessage = "Couldn't send your report. Please try again."
        }
    }
}

extension Report.Reason {
    var displayName: String {
        switch self {
        case .harassment: "Harassment or unsafe behavior"
        case .noShow: "No-show / repeated unreliability"
        case .misleading: "Misleading Match information"
        case .other: "Other"
        }
    }
}
