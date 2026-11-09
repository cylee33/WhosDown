import Testing
@testable import WhosDown

@MainActor
struct ReportTests {
    @Test func validatesAndSubmitsPlayerWithMatchContextOnce() async {
        let repo = FakeReportRepository()
        let model = ReportViewModel(reporterId: "alex", reportedUserId: "sam", matchId: "m1", reports: repo)
        #expect(!model.canSubmit)
        model.reason = .harassment
        model.details = "  Unsafe behavior  "
        #expect(model.canSubmit)
        await model.submit()
        await model.submit()
        #expect(model.submitted)
        #expect(repo.submissions.count == 1)
        #expect(repo.submissions.first?.details == "Unsafe behavior")
        #expect(repo.submissions.first?.reportedUserId == "sam")
        #expect(repo.submissions.first?.matchId == "m1")
    }
    @Test func invalidTargetsAndLongDetails() {
        let model = ReportViewModel(reporterId: "alex", reportedUserId: "alex", matchId: nil, reports: FakeReportRepository())
        model.reason = .other
        #expect(!model.canSubmit)
        let match = ReportViewModel(reporterId: "alex", reportedUserId: nil, matchId: "m1", reports: FakeReportRepository())
        match.reason = .other
        match.details = String(repeating: "x", count: 1001)
        #expect(!match.canSubmit)
    }
    @Test func failureAllowsRetry() async {
        let repo = FakeReportRepository()
        repo.shouldFail = true
        let model = ReportViewModel(reporterId: "alex", reportedUserId: nil, matchId: "m1", reports: repo)
        model.reason = .misleading
        await model.submit()
        #expect(!model.submitted)
        #expect(model.errorMessage != nil)
        #expect(model.canSubmit)
        repo.shouldFail = false
        await model.submit()
        #expect(model.submitted)
    }
}
