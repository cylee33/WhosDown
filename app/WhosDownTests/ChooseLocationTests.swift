import Foundation
import Testing
@testable import WhosDown

/// 1.12 Choose location.
struct VenueRulesTests {
    @Test func nearestFirstWithinRadius() {
        let far = Venue.sample("v_far", "North Park Fields", 40.6000, -80.0000)
        let sorted = VenueRules.sortedByDistance(Venue.samples + [far], from: .cmu, within: VenueRules.suggestionRadiusMeters)
        #expect(sorted.map(\.id) == ["v_cmu_soccer", "v_cmu_gym", "v_schenley_oval"])
    }

    @Test func sameVenueNeedsNearbyAndSimilarName() {
        let oval = Venue.samples[1]
        let nearbySameName = Place(name: "Schenley Oval Sports Complex", address: "", location: Coordinate(latitude: 40.43642, longitude: -79.94538))
        let nearbyOtherName = Place(name: "Schenley Park Café", address: "", location: Coordinate(latitude: 40.43642, longitude: -79.94538))
        let farSameName = Place(name: "Schenley Oval", address: "", location: Coordinate(latitude: 40.4500, longitude: -79.9454))
        #expect(VenueRules.existingVenue(for: nearbySameName, among: [oval])?.id == "v_schenley_oval")
        #expect(VenueRules.existingVenue(for: nearbyOtherName, among: [oval]) == nil)
        #expect(VenueRules.existingVenue(for: farSameName, among: [oval]) == nil)
    }

    @Test func textHelpers() {
        #expect(VenueRules.milesText(1609.344 * 1.24) == "1.2 mi")
        #expect(VenueRules.factsLine(Venue.samples[0]) == "Outdoor · Turf · Lights")
        #expect(VenueRules.factsLine(Venue.samples[2]) == "Indoor · Hardwood · Lights")
    }
}

@MainActor
struct ChooseLocationViewModelTests {
    private func makeViewModel(
        venues: FakeVenueRepository? = nil,
        location: Coordinate? = .cmu
    ) -> (ChooseLocationViewModel, FakeVenueRepository) {
        let venues = venues ?? FakeVenueRepository()
        let viewModel = ChooseLocationViewModel(
            userId: "seed_alex", venues: venues, placeSearch: FakePlaceSearchService(), location: FakeLocationService(location: location)
        )
        return (viewModel, venues)
    }

    @Test func suggestsSavedVenuesNearestFirstAndCentersOnCMUWithoutLocation() async {
        let (viewModel, _) = makeViewModel(location: nil)
        await viewModel.load()
        #expect(viewModel.center == .cmu)
        #expect(viewModel.suggestedVenues.map(\.name) == ["CMU Soccer Field", "CMU Wiegand Gym", "Schenley Oval"])
        #expect(viewModel.useButtonTitle == "Choose a place")
    }

    @Test func searchShowsSavedVenueFirstAndHidesItsMapsDuplicate() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()
        viewModel.query = "Schenley"
        await viewModel.search()
        #expect(viewModel.suggestedVenues.map(\.name) == ["Schenley Oval"])
        // "Schenley Oval Sports Complex" from Maps is the saved Venue, so only the tennis courts are new.
        #expect(viewModel.places.map(\.name) == ["Schenley Park Tennis Courts"])
    }

    @Test func choosingASavedVenueReturnsIt() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()
        viewModel.choose(viewModel.suggestedVenues[0])
        #expect(viewModel.useButtonTitle == "Use CMU Soccer Field")
        #expect(viewModel.confirm()?.id == "v_cmu_soccer")
    }

    @Test func newPlaceAsksThreeQuestionsThenSavesAVenue() async {
        let (viewModel, venues) = makeViewModel()
        await viewModel.load()
        let courts = Place(name: "Schenley Park Tennis Courts", address: "Overlook Dr", location: Coordinate(latitude: 40.4317, longitude: -79.9440))
        viewModel.choose(courts)
        #expect(viewModel.confirm() == nil)
        #expect(viewModel.placeNeedingFacts == courts)

        let venue = await viewModel.saveNewVenue(isIndoor: false, surface: .court, hasLights: true)
        #expect(venue?.name == "Schenley Park Tennis Courts")
        #expect(venue?.surface == "court")
        #expect(venue?.createdBy == "seed_alex")
        #expect(venues.created.count == 1)
        #expect(viewModel.placeNeedingFacts == nil)
    }

    @Test func choosingAPlaceNextToASavedVenueReusesIt() async {
        let (viewModel, venues) = makeViewModel()
        await viewModel.load()
        viewModel.choose(Place(name: "CMU Soccer Field", address: "", location: Coordinate(latitude: 40.44331, longitude: -79.94361)))
        #expect(viewModel.confirm()?.id == "v_cmu_soccer")
        #expect(venues.created.isEmpty)
    }

    @Test func offlineSaysSearchNeedsAConnection() async {
        let venues = FakeVenueRepository()
        venues.nextError = URLError(.notConnectedToInternet)
        let (viewModel, _) = makeViewModel(venues: venues)
        await viewModel.load()
        #expect(viewModel.message == "Search needs a connection.")
    }
}
