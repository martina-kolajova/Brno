//
//  BrnoMapView.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//
import SwiftUI
import MapKit

struct BrnoMapView: UIViewRepresentable {

    let service: KontejneryServicing

    init(service: KontejneryServicing = KontejneryService()) {
        self.service = service
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(service: service)
    }

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

        // ✅ test pin (kdyby se něco rozbilo, aspoň víš že mapa funguje)
        let test = MKPointAnnotation()
        test.coordinate = CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
        test.title = "TEST"
        map.addAnnotation(test)

        context.coordinator.loadPins(into: map)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    final class Coordinator: NSObject {
        private let service: KontejneryServicing
        private var didLoad = false

        init(service: KontejneryServicing) {
            self.service = service
        }

        func loadPins(into map: MKMapView) {
            guard !didLoad else { return }
            didLoad = true

            Task {
                do {
                    let stations = try await service.fetchStations(limit: 400)
                    print("✅ fetched stations:", stations.count)

                    let anns: [MKPointAnnotation] = stations.map { st in
                        let a = MKPointAnnotation()
                        a.coordinate = st.coordinate
                        a.title = st.title
                        a.subtitle = st.komodity.joined(separator: ", ")
                        return a
                    }

                    await MainActor.run {
                        map.addAnnotations(anns)
                        map.showAnnotations(anns, animated: false)
                        print("✅ added pins:", anns.count)
                    }
                } catch {
                    print("❌ fetch stations error:", error)
                }
            }
        }
    }
}



//
//struct BrnoMapView: UIViewRepresentable {
//
//    func makeUIView(context: Context) -> MKMapView {
//        let map = MKMapView()
//
//        let region = MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
//        )
//        map.setRegion(region, animated: false)
//
//        map.mapType = .mutedStandard
//        map.overrideUserInterfaceStyle = .light
//
//        map.pointOfInterestFilter = .excludingAll
//        map.showsBuildings = false
//        map.showsTraffic = false
//        map.showsCompass = false
//        map.showsScale = false
//
//
//        return map
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {}
//}

#Preview {
    BrnoMapView()
}
