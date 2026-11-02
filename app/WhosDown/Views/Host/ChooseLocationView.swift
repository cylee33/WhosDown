import MapKit
import SwiftUI

/// H40 Choose location (1.12). Opened from Create Match (1.11) and Edit Match (1.18); hands back the chosen Venue.
struct ChooseLocationView: View {
    let onChosen: (Venue) -> Void

    @Environment(AppEnvironment.self) private var environment
    @Environment(Session.self) private var session
    @State private var viewModel: ChooseLocationViewModel?
    @State private var camera: MapCameraPosition = .region(Self.region(around: .cmu))

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(Color.background)
        .navigationTitle("Choose location")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard viewModel == nil, let userId = session.user?.id else { return }
            let viewModel = ChooseLocationViewModel(
                userId: userId, venues: environment.venues, placeSearch: environment.placeSearch, location: environment.location
            )
            self.viewModel = viewModel
            await viewModel.load()
            camera = .region(Self.region(around: viewModel.center))
        }
    }

    private func content(_ viewModel: ChooseLocationViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Color.textSecondary)
                        TextField("Search field, park, or address", text: $viewModel.query)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                    }
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: 44)
                    .background(Color.surface, in: .rect(cornerRadius: Radius.button))
                    .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(Color.border))

                    map(viewModel)

                    if let message = viewModel.message {
                        Text(message).font(.footnote).foregroundStyle(Color.destructive)
                    }

                    if !viewModel.suggestedVenues.isEmpty {
                        sectionTitle("SUGGESTED")
                        ForEach(viewModel.suggestedVenues) { venue in
                            row(
                                title: venue.name,
                                detail: "\(viewModel.distanceText(to: venue.location)) · \(VenueRules.factsLine(venue))",
                                isSelected: viewModel.choice == .venue(venue)
                            ) { viewModel.choose(venue) }
                        }
                    }
                    if !viewModel.places.isEmpty {
                        sectionTitle("OTHER PLACES")
                        ForEach(viewModel.places, id: \.self) { place in
                            row(
                                title: place.name,
                                detail: "\(viewModel.distanceText(to: place.location)) · \(place.address)",
                                isSelected: viewModel.choice == .place(place)
                            ) { viewModel.choose(place) }
                        }
                    }
                }
                .padding(Spacing.m)
            }
            Button(viewModel.useButtonTitle) {
                if let venue = viewModel.confirm() { onChosen(venue) }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.choice == nil)
            .opacity(viewModel.choice == nil ? 0.5 : 1)
            .padding(Spacing.m)
        }
        .task(id: viewModel.query) {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
        .onChange(of: viewModel.choice) { _, choice in
            if let choice { withAnimation { camera = .region(Self.region(around: choice.location, meters: 1500)) } }
        }
        .sheet(item: $viewModel.placeNeedingFacts) { place in
            NewVenueSheet(place: place, isWorking: viewModel.isWorking) { indoor, surface, lights in
                Task {
                    if let venue = await viewModel.saveNewVenue(isIndoor: indoor, surface: surface, hasLights: lights) {
                        onChosen(venue)
                    }
                }
            }
        }
    }

    private func map(_ viewModel: ChooseLocationViewModel) -> some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(viewModel.suggestedVenues) { venue in
                Annotation(venue.name, coordinate: venue.location.clLocation) {
                    pin(selected: viewModel.choice == .venue(venue))
                        .onTapGesture { viewModel.choose(venue) }
                }
            }
            if case .place(let place) = viewModel.choice {
                Annotation(place.name, coordinate: place.location.clLocation) { pin(selected: true) }
            }
        }
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: Radius.card))
    }

    private func pin(selected: Bool) -> some View {
        Circle()
            .fill(selected ? Color.brand : Color.textPrimary)
            .frame(width: selected ? 22 : 16, height: selected ? 22 : 16)
            .overlay(Circle().stroke(.white, lineWidth: 2))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary).padding(.top, Spacing.xs)
    }

    private func row(title: String, detail: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                Text(detail).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s)
            .background(Color.surface, in: .rect(cornerRadius: Radius.button))
            .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(isSelected ? Color.brand : Color.border, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func region(around coordinate: Coordinate, meters: Double = 5000) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coordinate.clLocation, latitudinalMeters: meters, longitudinalMeters: meters)
    }
}

extension Coordinate {
    var clLocation: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

extension Place: Identifiable {
    var id: String { "\(name)|\(location.latitude)|\(location.longitude)" }
}

/// The three quick questions for a place that isn't a saved Venue yet (1.12 rule 3).
struct NewVenueSheet: View {
    let place: Place
    let isWorking: Bool
    let onSave: (_ isIndoor: Bool, _ surface: Surface, _ hasLights: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isIndoor = false
    @State private var surface: Surface = .turf
    @State private var hasLights = false

    var body: some View {
        SheetContainer(
            title: "About \(place.name)",
            message: "Three quick details so Players know what to expect.",
            primaryTitle: isWorking ? "Saving…" : "Save place",
            primaryAction: { onSave(isIndoor, surface, hasLights) },
            secondaryTitle: "Cancel",
            secondaryAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                WrappingHStack {
                    SelectableChip(title: "Outdoor", isSelected: !isIndoor) { isIndoor = false }
                    SelectableChip(title: "Indoor", isSelected: isIndoor) { isIndoor = true }
                }
                Text("SURFACE").font(.caption.weight(.semibold)).foregroundStyle(Color.textSecondary)
                WrappingHStack {
                    ForEach(Surface.allCases) { option in
                        SelectableChip(title: option.displayName, isSelected: surface == option) { surface = option }
                    }
                }
                Toggle("Lights", isOn: $hasLights).tint(Color.brand)
            }
        }
        .presentationDetents([.large])
        .disabled(isWorking)
    }
}

#Preview("H40") {
    let environment = AppEnvironment.preview()
    NavigationStack {
        ChooseLocationView(onChosen: { _ in })
    }
    .environment(environment)
    .environment(Session(auth: environment.auth, users: environment.users))
}
