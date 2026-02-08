//
//  BrnoMapViewModel.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.
//

import SwiftUI
import MapKit

class BrnoMapViewModel: ObservableObject {
    func findNearest(to location: CLLocationCoordinate2D, for filter: KomoditaFilter, in stations: [KontejnerStation]) -> KontejnerStation? {
        let userPos = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let validStations = stations.filter { st in
            st.komodity.contains { $0.localizedCaseInsensitiveContains(filter.rawValue) }
        }
        
        return validStations.min(by: {
            let d1 = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: userPos)
            let d2 = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: userPos)
            return d1 < d2
        })
    }
}
