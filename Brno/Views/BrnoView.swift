//
//  KontejneryMapScreen.swift
//  Brno
//
//  Created by Martina Kolajová on 01.02.2026.
//


import SwiftUI
import MapKit

struct KontejneryMapScreen: View {

    private let service: KontejneryServicing = KontejneryService()

    @State private var allStations: [KontejnerStation] = []
    @State private var selected: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
    @State private var streetQuery: String = ""
    @State private var errorText: String?

    @State private var camera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    var body: some View {
        ZStack(alignment: .top) {

            Map(position: $camera) {
                ForEach(filteredStations) { st in
                    Annotation(st.title, coordinate: st.coordinate) {
                        pinView(for: st)
                    }
                }
            }
            .ignoresSafeArea()

            FiltersBar(selected: $selected, streetQuery: $streetQuery)
                .padding(.top, 12)
        }
        .task { await load() }
        .alert("Chyba", isPresented: .constant(errorText != nil)) {
            Button("OK") { errorText = nil }
        } message: {
            Text(errorText ?? "")
        }
    }

    private var filteredStations: [KontejnerStation] {
        allStations.filter { st in
            selected.contains { st.matches($0) }
        }
    }

    @ViewBuilder
    private func pinView(for st: KontejnerStation) -> some View {
        let isHighlighted = st.matchesStreet(streetQuery)
        let color = isHighlighted ? Color.red : (st.dominantFilter()?.color ?? .gray)

        Circle()
            .fill(color)
            .frame(width: isHighlighted ? 18 : 12, height: isHighlighted ? 18 : 12)
            .overlay(Circle().stroke(.white, lineWidth: 2))
    }

    @MainActor
    private func load() async {
        do {
            let stations = try await service.fetchStations(limit: 2000)
            self.allStations = stations
            self.errorText = nil
            print("✅ loaded stations:", stations.count)
        } catch {
            self.errorText = error.localizedDescription
            print("❌ load error:", error)
        }
    }
}
