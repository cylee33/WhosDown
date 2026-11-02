import SwiftUI

extension Sport {
    /// SF Symbol shown for the sport on H03 and on map pins.
    var symbolName: String {
        switch self {
        case .soccer: "soccerball"
        case .basketball: "basketball"
        case .tennis: "tennis.racket"
        case .volleyball: "volleyball"
        case .pickleball: "figure.pickleball"
        case .baseball: "baseball"
        case .football: "football"
        case .ultimate: "figure.disc.sports"
        case .other: "plus"
        }
    }
}

/// H03 Select your sports (1.4). Reused by 1.22 to edit sports, so it takes plain bindings.
struct SelectSportsView: View {
    @Binding var selectedSports: [Sport]
    @Binding var customSportName: String
    var buttonTitle = "Next"
    let canContinue: Bool
    let onContinue: () -> Void

    @State private var askingForCustomName = false
    @State private var draftCustomName = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.s - Spacing.xxs), count: 3)

    var body: some View {
        VStack(spacing: Spacing.m) {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    Text("Pick any — you can change these later.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    LazyVGrid(columns: columns, spacing: Spacing.s - Spacing.xxs) {
                        ForEach(Sport.allCases) { sport in
                            tile(sport)
                        }
                    }
                    Text("Can't find it? Choose Other to create any activity.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(Spacing.m)
            }
            Button(buttonTitle, action: onContinue)
                .buttonStyle(.primary)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
                .padding([.horizontal, .bottom], Spacing.m)
        }
        .background(Color.background)
        .alert("Name your activity", isPresented: $askingForCustomName) {
            TextField("e.g. Spikeball", text: $draftCustomName)
            Button("Add") {
                if let name = ProfileRules.cleanedCustomSportName(draftCustomName) {
                    customSportName = name
                    if !selectedSports.contains(.other) { selectedSports.append(.other) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Up to \(ProfileRules.customSportNameLimit) characters.")
        }
    }

    private func tile(_ sport: Sport) -> some View {
        let isSelected = selectedSports.contains(sport)
        let title = sport == .other && isSelected && !customSportName.isEmpty ? customSportName : sport.displayName
        return Button {
            if sport == .other && !isSelected {
                draftCustomName = customSportName
                askingForCustomName = true
            } else if let index = selectedSports.firstIndex(of: sport) {
                selectedSports.remove(at: index)
            } else {
                selectedSports.append(sport)
            }
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: sport.symbolName)
                    .font(.title2)
                    .frame(height: 32)
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(isSelected ? Color.brandSoft : Color.surface, in: .rect(cornerRadius: Radius.card))
            .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(isSelected ? Color.brand : Color.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// H42 Set skill levels (1.4). Reused by 1.22.
struct SkillLevelsView: View {
    let sports: [Sport]
    let customSportName: String
    @Binding var levels: [Sport: SkillLevel]
    var buttonTitle = "Continue"
    let canContinue: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.m) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Set a typical level for each selected sport.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    ForEach(sports) { sport in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(ProfileRules.sportName(sport.rawValue, customSportName: customSportName))
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            WrappingHStack {
                                ForEach(SkillLevel.allCases) { level in
                                    SelectableChip(title: level.displayName, isSelected: levels[sport] == level) {
                                        levels[sport] = level
                                    }
                                }
                            }
                        }
                    }
                    Text("These help recommendations only — they don't restrict what you can join.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.m)
            }
            Button(buttonTitle, action: onContinue)
                .buttonStyle(.primary)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
                .padding([.horizontal, .bottom], Spacing.m)
        }
        .background(Color.background)
    }
}

#Preview("H03") {
    @Previewable @State var sports: [Sport] = [.soccer, .tennis]
    @Previewable @State var custom = ""
    NavigationStack {
        SelectSportsView(selectedSports: $sports, customSportName: $custom, canContinue: true, onContinue: {})
            .navigationTitle("Select your sports")
    }
}

#Preview("H42") {
    @Previewable @State var levels: [Sport: SkillLevel] = [.soccer: .allLevels, .tennis: .casual]
    NavigationStack {
        SkillLevelsView(sports: [.soccer, .tennis], customSportName: "", levels: $levels, canContinue: true, onContinue: {})
            .navigationTitle("Set skill levels")
    }
}
