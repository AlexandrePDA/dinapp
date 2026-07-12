import Foundation
import MapKit
import Combine

@MainActor
final class LocationSearchService: NSObject, ObservableObject {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published var query: String = "" {
        didSet { completer.queryFragment = query }
    }

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
    }

    func resolve(_ completion: MKLocalSearchCompletion) async throws -> MKMapItem {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw LocationSearchError.notFound
        }
        return item
    }

    func reset() {
        query = ""
        suggestions = []
    }
}

extension LocationSearchService: @preconcurrency MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

enum LocationSearchError: Error {
    case notFound
}
