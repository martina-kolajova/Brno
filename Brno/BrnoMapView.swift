//
//  BrnoMapView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//
import SwiftUI
import MapKit

struct BrnoMapView: UIViewRepresentable {

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        map.setRegion(region, animated: false)

        map.mapType = .mutedStandard
        map.overrideUserInterfaceStyle = .light

        map.pointOfInterestFilter = .excludingAll
        map.showsBuildings = false
        map.showsTraffic = false
        map.showsCompass = false
        map.showsScale = false


        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}
}

#Preview {
    BrnoMapView()
}
