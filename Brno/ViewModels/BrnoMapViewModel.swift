import SwiftUI
import MapKit

class BrnoMapViewModel: ObservableObject {
    @Published var allStations: [KontejnerStation] = []
    @Published var selectedStationID: String? = nil
    @Published var selectedFilters: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
    @Published var streetQuery: String = ""
    
    // Funkce pro nalezení nejbližšího kontejneru
    func findNearest(to location: CLLocationCoordinate2D) {
        // Tady budeš počítat vzdálenost a posouvat kameru
        // Použij CLLocation(latitude:longitude:).distance(from:)
    }
    
    // Logika pro filtrování stanic (volá se v BrnoView)
    func filteredStations() -> [KontejnerStation] {
        allStations.filter { st in
            let matchStreet = streetQuery.isEmpty || st.ulice.localizedCaseInsensitiveContains(streetQuery)
            let hasVisibleKomodita = st.komodity.contains { komStr in
                selectedFilters.contains { filter in 
                    komStr.localizedCaseInsensitiveContains(filter.rawValue) 
                }
            }
            return matchStreet && hasVisibleKomodita
        }
    }
}