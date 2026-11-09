import MapKit
import SwiftUI

/// Where Discover can lead: Match details (1.8), its roster (1.10), and Player profiles (1.22).
enum DiscoverRoute: Hashable {
    case match(String)
    case roster(Match)
    case player(String)
}

/// The Discover tab: H06 map and H07 list (1.5, 1.6), filters (1.7), and "Next up".
struct DiscoverView: View {
    /// H06's empty state offers to host a Match (1.5 rule 9).
    var onCreateMatch: () -> Void = {}
    var initialMode: DiscoverViewModel.Mode = .map

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: DiscoverViewModel?
    @State private var path: [DiscoverRoute] = []
    @State private var showingFilters = false
    @State private var showInbox = false
    @State private var unread = 0

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .background(Color.background)
            .navigationTitle(viewModel?.mode == .list ? "Matches near you" : "WhosDown")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !session.isGuest {
                        BellButton(count: unread) { showInbox = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingFilters = true } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .overlay(alignment: .topTrailing) {
                                if let count = viewModel?.filter.activeCount, count > 0 {
                                    Text("\(count)")
                                        .font(.caption2.bold()).foregroundStyle(Color.onBrand)
                                        .padding(Spacing.xxs).background(Color.brand, in: .circle)
                                        .offset(x: Spacing.xs, y: -Spacing.xs)
                                }
                            }
                    }
                    .accessibilityLabel("Filters")
                }
            }
            .navigationDestination(isPresented: $showInbox) { NotificationsView() }
            .navigationDestination(for: DiscoverRoute.self) { route in
                switch route {
                case .match(let id):
                    MatchDetailView(matchId: id) { sport in
                        viewModel?.showSimilar(sport: sport)
                        path.removeAll()
                    }
                case .roster(let match): RosterView(match: match)
                case .player(let id): PlayerProfileView(userId: id)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            if let viewModel { FiltersSheet(viewModel: viewModel) }
        }
        .task(id: session.user?.id) {
            let viewModel = DiscoverViewModel(
                userId: session.user?.id, isGuest: session.isGuest, matches: environment.matches,
                rsvps: environment.rsvps, users: environment.users, location: environment.location
            )
            viewModel.mode = initialMode
            self.viewModel = viewModel
            await viewModel.load()
        }
        .task(id: session.user?.id) {
            guard let userId = session.user?.id, !session.isGuest else { unread = 0; return }
            do {
                for try await items in environment.notifications.inbox(userId: userId) {
                    unread = items.filter { !$0.isRead }.count
                }
            } catch {
                unread = 0
            }
        }
    }

    private func content(_ viewModel: DiscoverViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: Spacing.s) {
            if let next = viewModel.nextUp {
                NextUpCard(match: next) { path.append(.match(next.id ?? "")) }
                    .padding(.horizontal, Spacing.m)
            }
            Picker("View", selection: $viewModel.mode) {
                Text("Map").tag(DiscoverViewModel.Mode.map)
                Text("List").tag(DiscoverViewModel.Mode.list)
            }
            .adaptiveSegmentedPicker()
            .padding(.horizontal, Spacing.m)

            if case .failed(let message) = viewModel.state {
                ContentUnavailableView("Something went wrong", systemImage: "wifi.exclamationmark", description: Text(message))
            } else {
                switch viewModel.mode {
                case .map:
                    DiscoverMapView(viewModel: viewModel) { path.append(.match($0)) }
                case .list:
                    DiscoverListView(viewModel: viewModel, onOpen: { path.append(.match($0)) },
                                     onFilters: { showingFilters = true }, onCreateMatch: onCreateMatch)
                }
            }
        }
    }
}

/// "Next up": the Player's next approved Match (1.5 rule 6).
struct NextUpCard: View {
    let match: Match
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var columns: AnyLayout { dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs)) : AnyLayout(HStackLayout(spacing: Spacing.s)) }

    var body: some View {
        Button(action: onOpen) {
            columns {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("NEXT UP").font(.caption2.weight(.bold)).foregroundStyle(Color.brand)
                    Text("\(match.title) · \(MatchFormatting.when(match))")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.textPrimary).fixedSize(horizontal: false, vertical: true)
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: Spacing.xxs) {
                    Text(match.venueName).font(.caption).foregroundStyle(Color.textSecondary).fixedSize(horizontal: false, vertical: true)
                    Text("Approved ✓").font(.caption.weight(.semibold)).foregroundStyle(Color.statusApproved)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.s)
            .background(Color.surface, in: .rect(cornerRadius: Radius.button))
            .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(Color.border))
        }
        .buttonStyle(.plain)
    }
}

/// H06 Discover map: radius circle, one sport pin per Venue, and a card for the tapped pin.
struct DiscoverMapView: View {
    let viewModel: DiscoverViewModel
    let onOpen: (String) -> Void

    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedPin: VenuePin?
    @State private var settledCenter: Coordinate?
    @State private var recentering = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                UserAnnotation()
                MapCircle(center: viewModel.center.clLocation, radius: viewModel.radiusMeters)
                    .foregroundStyle(Color.brand.opacity(0.08))
                    .stroke(Color.brand.opacity(0.5), lineWidth: 1)
                ForEach(viewModel.pins) { pin in
                    Annotation(pin.matches[0].venueName, coordinate: pin.location.clLocation) {
                        Button { selectedPin = pin } label: {
                            SportPin(pin: pin, isSelected: selectedPin?.id == pin.id)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                settledCenter = Coordinate(latitude: context.region.center.latitude, longitude: context.region.center.longitude)
            }
            .task(id: settledCenter) {
                // Search again after the map has been still for half a second (1.5 rule 7).
                guard let settledCenter else { return }
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                await viewModel.mapSettled(at: settledCenter)
            }

            VStack(spacing: Spacing.s) {
                HStack {
                    if viewModel.userLocation == nil {
                        Label("Turn on location to see Matches near you", systemImage: "location.slash")
                            .font(.caption).padding(Spacing.xs)
                            .background(Color.surface, in: .capsule)
                    }
                    Spacer()
                    Button {
                        guard !recentering else { return }
                        recentering = true
                        Task {
                            defer { recentering = false }
                            await viewModel.recenter()
                            camera = .region(region(around: viewModel.center))
                        }
                    } label: {
                        Image(systemName: "location.fill").padding(Spacing.s).background(Color.surface, in: .circle)
                    }
                    .accessibilityLabel("Back to my location")
                    .disabled(recentering)
                    .overlay { if recentering { ProgressView() } }
                }
                if let pin = selectedPin {
                    ForEach(pin.matches.prefix(3)) { match in
                        MatchPinCard(match: match, distance: viewModel.distanceText(to: match)) { onOpen(match.id ?? "") }
                    }
                } else if viewModel.state == .loaded && viewModel.visibleMatches.isEmpty {
                    Text("No Matches nearby yet. Try a bigger radius or host one.")
                        .font(.footnote).padding(Spacing.s).frame(maxWidth: .infinity)
                        .background(Color.surface, in: .rect(cornerRadius: Radius.button))
                }
            }
            .padding(Spacing.s)
        }
        .clipShape(.rect(cornerRadius: Radius.card))
        .padding([.horizontal, .bottom], Spacing.s)
        .onAppear { camera = .region(region(around: viewModel.center)) }
        .onChange(of: viewModel.pins) { _, pins in
            if let selected = selectedPin { selectedPin = pins.first { $0.id == selected.id } }
        }
    }

    private func region(around center: Coordinate) -> MKCoordinateRegion {
        MKCoordinateRegion(center: center.clLocation, latitudinalMeters: viewModel.radiusMeters * 2.4, longitudinalMeters: viewModel.radiusMeters * 2.4)
    }
}

/// A sport icon on the map; muted when every Match there is Full, with a count for several Matches (1.5 rules 3–4).
struct SportPin: View {
    let pin: VenuePin
    let isSelected: Bool

    var body: some View {
        Image(systemName: pin.sport.symbolName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.onBrand)
            .frame(width: isSelected ? 38 : 32, height: isSelected ? 38 : 32)
            .background(pin.isFull ? Color.textSecondary : (isSelected ? Color.brand : Color.textPrimary), in: .circle)
            .overlay(Circle().stroke(Color.onBrand, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if pin.matches.count > 1 {
                    Text("\(pin.matches.count)")
                        .font(.caption2.bold()).foregroundStyle(Color.onBrand)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Color.brand, in: .circle)
                        .offset(x: Spacing.xs, y: -Spacing.xs)
                }
            }
            .accessibilityLabel("\(pin.matches.count) Matches at \(pin.matches[0].venueName)")
    }
}

/// The card under the map for a tapped pin (H06).
struct MatchPinCard: View {
    let match: Match
    let distance: String
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: Spacing.s) {
                Image(systemName: match.sport.symbolName)
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Color.brandSoft, in: .rect(cornerRadius: Radius.button))
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(match.title).font(.headline).foregroundStyle(Color.textPrimary)
                    Text("\(MatchFormatting.when(match)) · \(distance)").font(.subheadline).foregroundStyle(Color.textSecondary)
                    MatchChips(match: match)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.s)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
    }
}

/// Level, count (or "Full"), and price chips, shared by the pin card and list rows.
struct MatchChips: View {
    let match: Match

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Chip(text: match.skillLevel.displayName)
            if match.isFull {
                Chip(text: "Full", foreground: .statusWaitlisted, background: .statusWaitlistedSoft)
            } else {
                Chip(text: MatchFormatting.count(match), foreground: .info, background: .info.opacity(0.1))
            }
            Chip(text: MatchFormatting.price(match), foreground: .textPrimary, background: .border.opacity(0.5))
        }
    }
}

/// H07 Discover list.
struct DiscoverListView: View {
    let viewModel: DiscoverViewModel
    let onOpen: (String) -> Void
    let onFilters: () -> Void
    let onCreateMatch: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        Menu {
                            Button("Any sport") { viewModel.setSportShortcut(nil) }
                            ForEach(Sport.allCases) { sport in
                                Button(sport.displayName) { viewModel.setSportShortcut(sport) }
                            }
                        } label: {
                            quickChip(viewModel.filter.sports.count == 1 ? viewModel.filter.sports.first!.displayName : "Sport",
                                      isOn: !viewModel.filter.sports.isEmpty)
                        }
                        Button { viewModel.toggleTonight() } label: {
                            quickChip("Tonight", isOn: viewModel.filter.time == .tonight)
                        }
                        Button(action: onFilters) {
                            quickChip(String(format: "≤ %g mi", viewModel.radiusMiles), isOn: false)
                        }
                        Button(action: onFilters) {
                            quickChip("Filters \(viewModel.filter.activeCount)", isOn: viewModel.filter.activeCount > 0)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.state == .loading {
                    ProgressView().frame(maxWidth: .infinity).padding(Spacing.xl)
                } else if viewModel.visibleMatches.isEmpty {
                    VStack(spacing: Spacing.s) {
                        ContentUnavailableView("No Matches nearby yet", systemImage: "sportscourt",
                                               description: Text("Try a bigger radius or host one."))
                        Button("Host a Match", action: onCreateMatch).buttonStyle(.secondary)
                    }
                } else {
                    ForEach(viewModel.visibleMatches) { match in
                        Button { onOpen(match.id ?? "") } label: {
                            MatchRow(match: match, distance: viewModel.distanceText(to: match))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.m)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func quickChip(_ title: String, isOn: Bool) -> some View {
        Text(title)
            .font(.subheadline.weight(isOn ? .semibold : .regular))
            .foregroundStyle(isOn ? Color.brand : Color.textPrimary)
            .padding(.horizontal, Spacing.s - Spacing.xxs)
            .padding(.vertical, Spacing.xs)
            .background(isOn ? Color.brandSoft : Color.surface, in: .capsule)
            .overlay(Capsule().stroke(isOn ? Color.brand : Color.border))
    }
}

/// One row on H07: sport icon, title, "7:00 PM · CMU Soccer Field · 0.4 mi", chips (1.6 rule 2).
struct MatchRow: View {
    let match: Match
    let distance: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: match.sport.symbolName)
                .font(.title2)
                .frame(width: 56, height: 56)
                .background(Color.brandSoft, in: .rect(cornerRadius: Radius.button))
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(match.title).font(.headline).foregroundStyle(Color.textPrimary)
                Text("\(MatchFormatting.when(match)) · \(match.venueName) · \(distance)")
                    .font(.subheadline).foregroundStyle(Color.textSecondary).lineLimit(2)
                MatchChips(match: match)
            }
            Spacer(minLength: 0)
        }
        .card()
    }
}

#Preview("Discover") {
    let environment = AppEnvironment.preview()
    DiscoverView()
        .environment(environment)
        .environment(Session(auth: environment.auth, users: environment.users))
}
