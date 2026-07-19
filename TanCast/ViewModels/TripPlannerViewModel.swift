import SwiftUI
import Combine

@MainActor
final class TripPlannerViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [GeoLocation] = []
    @Published var selectedDestination: GeoLocation?
    @Published var startDate: Date = Date().addingTimeInterval(7 * 86400)
    @Published var endDate: Date = Date().addingTimeInterval(14 * 86400)
    @Published var tripPlan: TripPlan?
    @Published var isSearching = false
    @Published var isLoadingPlan = false
    @Published var error: String?

    private let geocodingService = GeocodingService()
    private let uvService = TripUVService()
    private var searchTask: Task<Void, Never>?

    var canPlan: Bool {
        selectedDestination != nil && startDate < endDate
    }

    var dateRangeValid: Bool {
        endDate > startDate
    }

    func search() {
        searchTask?.cancel()
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            isSearching = true
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                searchResults = try await geocodingService.search(query: searchQuery)
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
            isSearching = false
        }
    }

    func selectDestination(_ location: GeoLocation) {
        selectedDestination = location
        searchQuery = location.displayName
        searchResults = []
    }

    func buildPlan(skinType: FitzpatrickType) async {
        guard let destination = selectedDestination else { return }
        isLoadingPlan = true
        error = nil
        do {
            let forecasts = try await uvService.fetch(
                latitude: destination.latitude,
                longitude: destination.longitude,
                startDate: startDate,
                endDate: endDate
            )
            tripPlan = TripPlan(
                destination: destination,
                startDate: startDate,
                endDate: endDate,
                dailyForecasts: forecasts
            )
        } catch {
            self.error = "Couldn't load forecast. Check your connection."
        }
        isLoadingPlan = false
    }

    func reset() {
        tripPlan = nil
        selectedDestination = nil
        searchQuery = ""
        searchResults = []
        error = nil
    }
}
