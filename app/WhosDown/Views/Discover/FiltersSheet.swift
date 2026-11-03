import SwiftUI

/// H08 Filters (1.7): sport, time, distance, skill, join type. Edits a copy; "Show N Matches" applies it.
struct FiltersSheet: View {
    let viewModel: DiscoverViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draft = MatchFilter()
    @State private var radiusText = ""
    @State private var customFirstDay = Date.now
    @State private var customLastDay = Date.now.addingTimeInterval(6 * 86400)
    @State private var customFrom = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now
    @State private var customTo = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
    @State private var useCustomDays = true
    @State private var useCustomTimes = true

    private enum TimeChoice: String, CaseIterable { case any = "Any time", now = "Now", tonight = "Tonight", tomorrow = "Tomorrow", custom = "Custom" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    section("SPORT") {
                        WrappingHStack {
                            ForEach(Sport.allCases) { sport in
                                SelectableChip(title: sport.displayName, isSelected: draft.sports.contains(sport)) {
                                    if draft.sports.contains(sport) { draft.sports.remove(sport) } else { draft.sports.insert(sport) }
                                }
                            }
                        }
                    }

                    section("TIME") {
                        WrappingHStack {
                            ForEach(TimeChoice.allCases, id: \.self) { choice in
                                SelectableChip(title: choice.rawValue, isSelected: timeChoice == choice) { select(choice) }
                            }
                        }
                        if timeChoice == .custom {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Toggle("Choose days", isOn: $useCustomDays).tint(Color.brand)
                                if useCustomDays {
                                    DatePicker("From", selection: $customFirstDay, displayedComponents: .date)
                                    DatePicker("To", selection: $customLastDay, in: customFirstDay..., displayedComponents: .date)
                                }
                                Toggle("Choose time of day", isOn: $useCustomTimes).tint(Color.brand)
                                if useCustomTimes {
                                    DatePicker("From", selection: $customFrom, displayedComponents: .hourAndMinute)
                                    DatePicker("To", selection: $customTo, displayedComponents: .hourAndMinute)
                                }
                            }
                            .card()
                            .onChange(of: [customFirstDay, customLastDay, customFrom, customTo]) { updateCustom() }
                            .onChange(of: useCustomDays) { updateCustom() }
                            .onChange(of: useCustomTimes) { updateCustom() }
                        }
                    }

                    section("DISTANCE") {
                        LabeledField(label: "Miles from you", error: radiusError) {
                            TextField("3", text: $radiusText).keyboardType(.decimalPad)
                        }
                    }

                    section("SKILL LEVEL") {
                        WrappingHStack {
                            ForEach(SkillLevel.allCases) { level in
                                SelectableChip(title: level.displayName, isSelected: draft.skillLevels.contains(level)) {
                                    if draft.skillLevels.contains(level) { draft.skillLevels.remove(level) } else { draft.skillLevels.insert(level) }
                                }
                            }
                        }
                        Text("All Levels Matches always show.").font(.footnote).foregroundStyle(Color.textSecondary)
                    }

                    section("JOIN TYPE") {
                        Picker("Join type", selection: $draft.joinType) {
                            Text("Any").tag(JoinType?.none)
                            Text("Open").tag(JoinType?.some(.open))
                            Text("Approval").tag(JoinType?.some(.approvalRequired))
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(Spacing.m)
            }
            .safeAreaInset(edge: .bottom) {
                let count = viewModel.count(with: draft, radiusMiles: radius ?? viewModel.radiusMiles)
                Button("Show \(count) \(count == 1 ? "Match" : "Matches")") {
                    Task {
                        await viewModel.apply(draft, radiusMiles: radius ?? viewModel.radiusMiles)
                        dismiss()
                    }
                }
                .buttonStyle(.primary)
                .disabled(radiusError != nil)
                .padding(Spacing.m)
                .background(Color.background)
            }
            .background(Color.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Reset") { draft = MatchFilter() } }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            draft = viewModel.filter
            radiusText = String(format: "%g", viewModel.radiusMiles)
        }
    }

    private var radius: Double? {
        Double(radiusText.replacingOccurrences(of: ",", with: ".")).map { ($0 * 10).rounded() / 10 }
    }

    /// Rule 3: 0.5–25 miles, one decimal.
    private var radiusError: String? {
        guard let radius else { return "Enter a number of miles." }
        return MatchFilter.radiusRange.contains(radius) ? nil : "Use 0.5 to 25 miles."
    }

    private var timeChoice: TimeChoice {
        switch draft.time {
        case .any: .any
        case .now: .now
        case .tonight: .tonight
        case .tomorrow: .tomorrow
        case .custom: .custom
        }
    }

    private func select(_ choice: TimeChoice) {
        switch choice {
        case .any: draft.time = .any
        case .now: draft.time = .now
        case .tonight: draft.time = .tonight
        case .tomorrow: draft.time = .tomorrow
        case .custom: updateCustom()
        }
    }

    private func updateCustom() {
        let calendar = Calendar.current
        func minutes(_ date: Date) -> Int { calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date) }
        draft.time = .custom(
            firstDay: useCustomDays ? customFirstDay : nil,
            lastDay: useCustomDays ? customLastDay : nil,
            fromMinute: useCustomTimes ? minutes(customFrom) : nil,
            toMinute: useCustomTimes ? minutes(customTo) : nil
        )
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
            content()
        }
    }
}
