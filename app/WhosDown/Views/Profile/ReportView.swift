import SwiftUI

struct ReportView: View {
    var reportedUserId: String? = nil
    var matchId: String? = nil
    var playerName: String? = nil
    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReportViewModel?

    var body: some View {
        ScrollView {
            if let viewModel {
                @Bindable var model = viewModel
                VStack(alignment: .leading, spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("How WhosDown handles safety").font(.headline).foregroundStyle(Color.info)
                        Text("Reports are reviewed privately. Reporting won't change the reported Player's profile or notify them.")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.info.opacity(0.08), in: .rect(cornerRadius: Radius.card))
                    Text(playerName.map { "Report \($0)" } ?? "Report this Match").font(.title2.bold())
                    ForEach(Report.Reason.allCases, id: \.self) { reason in
                        Button { model.reason = reason } label: {
                            Label(reason.displayName, systemImage: model.reason == reason ? "largecircle.fill.circle" : "circle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .card()
                        }.buttonStyle(.plain)
                        .accessibilityAddTraits(model.reason == reason ? .isSelected : [])
                    }
                    TextField("Add details (optional)", text: $model.details, axis: .vertical)
                        .lineLimit(4...8)
                        .card()
                        .onChange(of: model.details) { _, value in model.details = String(value.prefix(1000)) }
                    Text("\(model.details.count)/1000").font(.caption).foregroundStyle(Color.textSecondary)
                    if let error = model.errorMessage { Text(error).foregroundStyle(Color.destructive) }
                    Button { Task { await model.submit() } } label: {
                        if model.isWorking { ProgressView() } else { Text("Submit report") }
                    }.buttonStyle(.destructive).disabled(!model.canSubmit)
                    Text("Emergency? Contact local emergency services.").font(.footnote).foregroundStyle(Color.textSecondary)
                }.padding(Spacing.m)
                .alert("Thanks. We'll review your report.", isPresented: .constant(model.submitted)) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .background(Color.background)
        .navigationTitle("Safety & reporting")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let user = session.user, !user.isGuest else { return }
            viewModel = ReportViewModel(reporterId: user.id, reportedUserId: reportedUserId, matchId: matchId, reports: environment.reports)
        }
    }
}
