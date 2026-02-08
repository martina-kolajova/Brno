//
//  BrnoView 2.swift
//  Brno
//
//  Created by Martina Kolajová on 07.02.2026.

import SwiftUI
import MapKit



struct BrnoView: View {
    let allStations: [KontejnerStation]
    @StateObject private var vm = BrnoMapViewModel()
    
    @State private var selected: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
    @State private var streetQuery: String = "" // Toto je text v horní liště
    @State private var selectedStationID: String? = nil
    @State private var selectedStation: KontejnerStation? = nil
    
    @State private var camera = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MAPA
            Map(position: $camera) {
                if currentRegion.span.latitudeDelta < 0.03 {
                    ForEach(filteredStations) { st in
                        Annotation(st.title, coordinate: st.coordinate) {
                            PiePinView(
                                viewModel: PiePinViewModel(station: st, activeFilters: selected),
                                isSelected: selectedStationID == st.id
                            )
                            .onTapGesture {
                                selectStationFromMap(st)
                            }
                        }
                    }
                }
                UserAnnotation()
            }
            .onMapCameraChange { context in
                currentRegion = context.region
            }
            .ignoresSafeArea()

            // HORNÍ LIŠTA (Ovládací centrum)
            VStack {
                HStack {
                    // Tady je tvoje pole pro ulici
                    TextField("Zadejte ulici nebo vyberte z mapy...", text: $streetQuery)
                        .padding(12)
                        .background(.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    
                    // PLUS TLAČÍTKO (Navigovat z adresy v liště)
                    Button(action: startNavigationFromList) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.red)
                            .background(Circle().fill(.white))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Rychlé filtry pod lištou
                FiltersBar(selected: $selected, streetQuery: .constant("")) // Upraveno pro UI
                Spacer()
            }

            // TLAČÍTKO GPS (Dole)
            VStack {
                Button(action: centerOnUserAndGetAddress) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .frame(width: 56, height: 56)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // 1. Akce: Kliknutí na stanoviště v mapě
    private func selectStationFromMap(_ st: KontejnerStation) {
        withAnimation {
            selectedStationID = st.id
            selectedStation = st
            streetQuery = st.ulice // Vypíše ulici do horní lišty
            camera = .region(MKCoordinateRegion(
                center: st.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    // 2. Akce: GPS zaměření
    private func centerOnUserAndGetAddress() {
        withAnimation {
            camera = .userLocation(fallback: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
            // Zde by ideálně proběhl Reverse Geocoding pro zjištění ulice z GPS
            streetQuery = "Moje poloha"
        }
    }

    // 3. Akce: Stisk PLUS (Navigace k nejbližšímu podle textu v liště)
    private func startNavigationFromList() {
        // Pokud uživatel vybral konkrétní stanoviště, navigujeme tam
        // Pokud jen napsal ulici, najdeme nejbližší stanoviště k centru mapy
        if let nearest = vm.findNearest(to: currentRegion.center, in: filteredStations) {
            withAnimation(.spring()) {
                camera = .region(MKCoordinateRegion(
                    center: nearest.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
                selectedStationID = nearest.id
                streetQuery = nearest.ulice
            }
        }
    }

    private var filteredStations: [KontejnerStation] {
        allStations.filter { st in
            let matchStreet = streetQuery.isEmpty || streetQuery == "Moje poloha" || st.ulice.localizedCaseInsensitiveContains(streetQuery)
            let hasVisibleKomodita = st.komodity.contains { komStr in
                selected.contains { filter in komStr.localizedCaseInsensitiveContains(filter.rawValue) }
            }
            return matchStreet && hasVisibleKomodita
        }
    }
}
