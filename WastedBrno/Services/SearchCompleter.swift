import Foundation
import MapKit
import os

// MARK: - Search Completer
// Provides address auto-complete suggestions as the user types in the search bar.
// Wraps Apple's MKLocalSearchCompleter and filters results to only show Brno addresses.
// Used by: BrnoView (search bar) → user types "Česká" → shows "Česká, Brno-střed"

final class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    private let logger = Logger(subsystem: "com.WastedBrno", category: "SearchCompleter")

    /// The list of matching address suggestions — displayed in the autocomplete dropdown.
    @Published var results: [MKLocalSearchCompletion] = []

    /// Apple's built-in search completer that queries Apple Maps for address matches.
    private var completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        // Bias results toward Brno area so the user gets relevant suggestions
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        // Only show address results (not businesses or points of interest)
        completer.resultTypes = .address
    }

    /// Called by the search bar every time the user types a character.
    /// Passes the partial text to Apple Maps for autocomplete.
    func update(query: String) {
        completer.queryFragment = query
    }

    /// Delegate callback — Apple Maps returned new suggestions.
    /// We filter to only keep results that contain "Brno" in the subtitle.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter { $0.subtitle.contains("Brno") }
    }

    /// Delegate callback — the search failed (e.g. no network).
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        logger.error("❌ Search autocomplete failed: \(error.localizedDescription)")
    }
}
