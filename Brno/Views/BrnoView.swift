import SwiftUI
import MapKit
import CoreLocation



// MARK: - 1. Správca polohy
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var currentStreetName: String = ""

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.lastLocation = location
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let street = placemarks?.first?.thoroughfare {
                DispatchQueue.main.async { self.currentStreetName = street }
            }
        }
    }
}

// MARK: - 2. Našepkávač všetkých ulíc
class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private var completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        completer.resultTypes = .address
    }
    
    func update(query: String) { completer.queryFragment = query }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results.filter { $0.subtitle.contains("Brno") }
    }
}


struct BrnoView: View {
    let allStations: [KontejnerStation]

    @StateObject private var vm = BrnoMapViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()

    @State private var streetQuery: String = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
            controlsLayer
            floatingButtons
        }
        .onChange(of: streetQuery) { newValue in
            if isSearchFocused { searchCompleter.update(query: newValue) }
        }
    }

    // MARK: - Map
    private var mapLayer: some View {
        Map(position: $vm.camera) {
            ForEach(vm.filteredStations(allStations)) { st in
                Annotation(st.ulice, coordinate: st.coordinate) {
                    PiePinView(
                        station: st,
                        activeFilters: vm.selectedFilters,
                        isSelected: vm.selectedStation?.id == st.id,
                        spanDelta: vm.mapRegion.span.latitudeDelta
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isSearchFocused = false
                            vm.selectStation(st)
                        }
                    }
                }
            }

            if let searchPoint = vm.activeSearchPoint {
                Annotation("Východzí bod", coordinate: searchPoint) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white))
                        .shadow(radius: 3)
                }
            }

            if let route = vm.route {
                MapPolyline(route.polyline)
                    .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            UserAnnotation()
        }
        .onMapCameraChange { context in vm.mapRegion = context.region }
        .ignoresSafeArea()
        .sheet(item: $vm.selectedStation) { station in
            DetailStationPanel(
                station: station,
                navInfo: vm.routeDistance.isEmpty ? nil : "\(vm.routeDistance) • \(vm.routeTravelTime)",
                onNavigate: { vm.calculateRoute(to: station.coordinate, userLocation: locationManager.lastLocation) },
                onClose: { vm.clearStation() },
                detent: $vm.detent
            )
           
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.scrolls)
            .presentationDetents([.fraction(0.37), .large, .height(70)], selection: $vm.detent)
            .onAppear { vm.detent = .fraction(0.37) }
        }
    }

    // MARK: - Top controls
    private var controlsLayer: some View {
        VStack(spacing: 0) {
            FiltersBar(selected: $vm.selectedFilters, streetQuery: $streetQuery)
                .focused($isSearchFocused)
                .padding(.top, 10)

            if isSearchFocused && !searchCompleter.results.isEmpty {
                searchSuggestions
            }

            if vm.showNavigationPanel {
                QuickNavButtons { filter in
                    vm.startQuickNavigation(for: filter, in: allStations, userLocation: locationManager.lastLocation)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 10)
            }

            Spacer()
        }
    }

    private var searchSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(searchCompleter.results, id: \.self) { result in
                    Button {
                        vm.selectAddress(result)
                        streetQuery = result.title
                        isSearchFocused = false
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title).foregroundStyle(.red)
                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal, 20)
        .padding(.top, 5)
        .frame(maxHeight: 200)
    }

    // MARK: - Floating buttons
    private var floatingButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.showNavigationPanel.toggle()
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(vm.showNavigationPanel ? .red : .white)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(vm.showNavigationPanel ? .white : .red)
                                    .shadow(color: .black.opacity(0.15), radius: 4)
                            )
                    }
                    .scaleEffect(vm.showNavigationPanel ? 0.95 : 1.0)

                    Button {
                        guard let loc = locationManager.lastLocation else { return }
                        vm.centerOnUser(location: loc)
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .buttonStyle(MagneticButtonStyle(isActive: false))
                }
                .padding(.trailing, 20)
                .padding(.bottom, vm.selectedStation == nil ? 40 : 320)
            }
        }
        .zIndex(10)
    }
}
//
//
////
//// MARK: - 3. Hlavné View
//struct BrnoView: View {
//    let allStations: [KontejnerStation]
//    @StateObject private var locationManager = LocationManager()
//    @StateObject private var searchCompleter = SearchCompleter()
//    @StateObject private var vm = BrnoMapViewModel()
//    
//    // Filtry a hledání
//    @State private var streetQuery: String = ""
//    @State private var selectedFilters: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
//    @FocusState private var isSearchFocused: Bool
//    
//    // Navigace a stavy
//    @State private var showNavigationPanel = false
//    @State private var selectedStation: KontejnerStation? = nil
//    @State private var route: MKRoute? = nil
//    @State private var routeDistance: String = ""
//    @State private var routeTravelTime: String = ""
//    @State private var activeSearchPoint: CLLocationCoordinate2D? = nil
//    
//    
//    @State private var detent: PresentationDetent = .height(70)   // “jen lišta”
//
//
//    // KAMERA A REGION
//    @State private var camera: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//    )))
//    
//    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//    )
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            // 1. VRSTVA: MAPA
//            Map(position: $camera) {
//                ForEach(allStations.filter { station in
//                    selectedFilters.isEmpty || selectedFilters.contains { filter in station.matches(filter) }
//                }) { st in
//                    let zoomScale = max(0.4, min(1.1, 0.02 / mapRegion.span.latitudeDelta))
//                    let isSelected = selectedStation?.id == st.id
//                    
//                    Annotation(st.ulice, coordinate: st.coordinate) {
//                        PiePinView(
//                            station: st,
//                            activeFilters: mapVM.selectedFilters,
//                            isSelected: mapVM.selectedStation?.id == st.id
//                        )
//                        .onTapGesture { mapVM.selectStation(st) }
//                    
//                    }
//                }
//                
//                if let searchPoint = activeSearchPoint {
//                    Annotation("Východzí bod", coordinate: searchPoint) {
//                        Image(systemName: "mappin.circle.fill")
//                            .font(.title).foregroundStyle(.red).background(Circle().fill(.white)).shadow(radius: 3)
//                    }
//                }
//                
//                if let route {
//                    MapPolyline(route.polyline)
//                        .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
//                }
//                
//                UserAnnotation()
//            }
//            .onMapCameraChange { context in mapRegion = context.region }
//            .ignoresSafeArea()
//
//            // 2. VRSTVA: HORNÍ LIŠTA A PANEL
//            VStack(spacing: 0) {
//                FiltersBar(selected: $selectedFilters, streetQuery: $streetQuery)
//                    .focused($isSearchFocused)
//                    .padding(.top, 10)
//                
//                if isSearchFocused && !searchCompleter.results.isEmpty {
//                    ScrollView {
//                        VStack(alignment: .leading, spacing: 0) {
//                            ForEach(searchCompleter.results, id: \.self) { result in
//                                Button { selectRealAddress(result) } label: {
//                                    VStack(alignment: .leading, spacing: 2) {
//                                        Text(result.title).foregroundStyle(.red)
//                                        Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
//                                    }
//                                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
//                                }
//                                Divider().padding(.horizontal, 16)
//                            }
//                        }
//                    }
//                    .background(Color(.systemBackground)).cornerRadius(15).shadow(radius: 5).padding(.horizontal, 20).padding(.top, 5)
//                    .frame(maxHeight: 200)
//                }
//
//                if showNavigationPanel {
//                    QuickNavButtons { filter in startQuickNavigation(for: filter) }
//                        .transition(.move(edge: .top).combined(with: .opacity))
//                        .padding(.top, 10)
//                }
//                Spacer()
//            }
//            
//
//            .sheet(item: $selectedStation) { station in
//                DetailStationPanel(
//                    station: station,
//                    navInfo: routeDistance.isEmpty ? nil : "\(routeDistance) • \(routeTravelTime)",
//                    onNavigate: { calculateRoute(to: station.coordinate) },
//                    onClose: { selectedStation = nil },
//                    detent: $detent
//                )
//                .presentationDetents([.height(70), .medium, .large], selection: $detent)
//                .presentationDragIndicator(.visible)
//                .presentationContentInteraction(.scrolls)
//                .onAppear {
//                    detent = .height(60) // ✅ po otevření zasunout na “jen lištu”
//                }
//            }
//
//
//
//            // 4. VRSTVA: PLOVOUCÍ TLAČÍTKA (PŘESNĚ SEM!)
//            // Tlačítka v pravém dolním rohu
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    VStack(spacing: 16) {
//
//                        // 1️⃣ TLAČÍTKO (Kontejner / Navigace)
//                        Button(action: {
//                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                showNavigationPanel.toggle()
//                            }
//                        }) {
//                            Image(systemName: "trash.fill")
//                                .foregroundStyle(showNavigationPanel ? .red : .white)   // 🔁 reversed correctly
//                                .font(.system(size: 18, weight: .semibold))
//                                .frame(width: 50, height: 50)
//                                .background(
//                                    Circle()
//                                        .fill(showNavigationPanel ? .white : .red)      // 🔁 reversed correctly
//                                        .shadow(color: .black.opacity(0.15), radius: 4)
//                                )
//                        }
//                        .scaleEffect(showNavigationPanel ? 0.95 : 1.0)
//
//                        // 2️⃣ ČERVENÉ TLAČÍTKO (Moje poloha)
//                        Button(action: findMe) {
//                            Image(systemName: "location.fill")
//                        }
//                        .buttonStyle(MagneticButtonStyle(isActive: false)) // independent style
//
//                    }
//                    .padding(.trailing, 20)
//                    .padding(.bottom, selectedStation == nil ? 40 : 320)
//                }
//            }
//            .zIndex(10) // EXTRÉMNĚ DŮLEŽITÉ - dává tlačítka nad mapu
//        }
//        .onChange(of: streetQuery) { newValue in
//            if isSearchFocused { searchCompleter.update(query: newValue) }
//        }
//    }
//
//    // --- LOGIKA ---
//    private func findMe() {
//        guard let userLoc = locationManager.lastLocation else { return }
//        activeSearchPoint = nil
//        withAnimation(.spring()) {
//            camera = .region(MKCoordinateRegion(center: userLoc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
//        }
//    }
//
//    private func selectRealAddress(_ completion: MKLocalSearchCompletion) {
//        let searchRequest = MKLocalSearch.Request(completion: completion)
//        let search = MKLocalSearch(request: searchRequest)
//        search.start { response, _ in
//            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
//            activeSearchPoint = coordinate
//            streetQuery = completion.title
//            isSearchFocused = false
//            withAnimation(.spring()) {
//                camera = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
//            }
//        }
//    }
//
//    private func selectStation(_ st: KontejnerStation) {
//        withAnimation(.spring()) {
//            selectedStation = st
//            route = nil
//            routeDistance = ""
//            isSearchFocused = false
//        }
//    }
//
//    private func startQuickNavigation(for filter: KomoditaFilter) {
//        let basePoint = activeSearchPoint ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
//        if let nearest = vm.findNearest(to: basePoint, for: filter, in: allStations) {
//            selectStation(nearest)
//            showNavigationPanel = false
//        }
//    }
//
//    private func calculateRoute(to destination: CLLocationCoordinate2D) {
//        let startPoint = activeSearchPoint ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPoint))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
//        request.transportType = .walking
//
//        Task {
//            let directions = MKDirections(request: request)
//            do {
//                let response = try await directions.calculate()
//                if let computedRoute = response.routes.first {
//                    await MainActor.run {
//                        withAnimation(.spring()) {
//                            self.route = computedRoute
//
//                            let dist = computedRoute.distance
//                            self.routeDistance = dist < 1000 ? "\(Int(dist)) m" : String(format: "%.1f km", dist / 1000)
//
//                            let minutes = Int(computedRoute.expectedTravelTime / 60)
//                            self.routeTravelTime = "\(minutes) min"
//
//                            let baseRegion = MKCoordinateRegion(computedRoute.polyline.boundingMapRect)
//                            let paddedRegion = MKCoordinateRegion(
//                                center: baseRegion.center,
//                                span: MKCoordinateSpan(
//                                    latitudeDelta: baseRegion.span.latitudeDelta * 1.45,
//                                    longitudeDelta: baseRegion.span.longitudeDelta * 1.45
//                                )
//                            )
//                            self.camera = .region(paddedRegion)
//                        }
//                    }
//                }
//
//
//            } catch {
//                print("Chyba trasy: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//
//
//
//struct BrnoView: View {
//    let allStations: [KontejnerStation]
//    
//    @StateObject private var locationManager = LocationManager()
//    @StateObject private var searchCompleter = SearchCompleter()
//    @StateObject private var vm = BrnoMapViewModel()
//    
//    @FocusState private var isSearchFocused: Bool
//    @State private var detent: PresentationDetent = .height(70)
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            // 1. VRSTVA: MAPA
//            Map(position: $vm.camera) {
//                ForEach(allStations.filter { station in
//                    vm.selectedFilters.isEmpty || vm.selectedFilters.contains { station.matches($0) }
//                }) { st in
//                    Annotation(st.ulice, coordinate: st.coordinate) {
//                        PiePinView(
//                            station: st,
//                            activeFilters: vm.selectedFilters,
//                            isSelected: vm.selectedStation?.id == st.id
//                        )
//                        .onTapGesture { vm.selectStation(st) }
//                    }
//                }
//                
//                if let searchPoint = vm.activeSearchPoint {
//                    Annotation("Východzí bod", coordinate: searchPoint) {
//                        Image(systemName: "mappin.circle.fill")
//                            .font(.title).foregroundStyle(.red).background(Circle().fill(.white)).shadow(radius: 3)
//                    }
//                }
//                
//                if let route = vm.route {
//                    MapPolyline(route.polyline)
//                        .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
//                }
//                
//                UserAnnotation()
//            }
//            .onMapCameraChange { context in vm.mapRegion = context.region }
//            .ignoresSafeArea()
//
//            // 2. VRSTVA: HORNÍ LIŠTA A PANEL
//            VStack(spacing: 0) {
//                FiltersBar(selected: $vm.selectedFilters, streetQuery: $vm.streetQuery)
//                    .focused($isSearchFocused)
//                    .padding(.top, 10)
//                
//                if isSearchFocused && !searchCompleter.results.isEmpty {
//                    searchSuggestionsList
//                }
//
//                if vm.showNavigationPanel {
//                    QuickNavButtons { filter in
//                        vm.startQuickNavigation(for: filter, allStations: allStations, locationManager: locationManager)
//                    }
//                    .transition(.move(edge: .top).combined(with: .opacity))
//                    .padding(.top, 10)
//                }
//                Spacer()
//            }
//            
//            // 3. VRSTVA: PLOVOUCÍ TLAČÍTKA
//            floatingActionButtons
//        }
//        .sheet(item: $vm.selectedStation) { station in
//            DetailStationPanel(
//                station: station,
//                navInfo: vm.routeDistance.isEmpty ? nil : "\(vm.routeDistance) • \(vm.routeTravelTime)",
//                onNavigate: { vm.calculateRoute(to: station.coordinate, locationManager: locationManager) },
//                onClose: { vm.selectedStation = nil },
//                detent: $detent
//            )
//            .presentationDetents([.height(70), .medium, .large], selection: $detent)
//            .presentationDragIndicator(.visible)
//            .onAppear { detent = .height(70) }
//        }
//        .onChange(of: vm.streetQuery) { newValue in
//            if isSearchFocused { searchCompleter.update(query: newValue) }
//        }
//    }
//}
//
//// MARK: - Pomocné View komponenty
//private extension BrnoView {
//    var searchSuggestionsList: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 0) {
//                ForEach(searchCompleter.results, id: \.self) { result in
//                    Button {
//                        vm.selectRealAddress(result)
//                        isSearchFocused = false
//                    } label: {
//                        VStack(alignment: .leading, spacing: 2) {
//                            Text(result.title).foregroundStyle(.red)
//                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
//                        }
//                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    Divider().padding(.horizontal, 16)
//                }
//            }
//        }
//        .background(Color(.systemBackground)).cornerRadius(15).shadow(radius: 5).padding(.horizontal, 20).padding(.top, 5)
//        .frame(maxHeight: 200)
//    }
//    
//    // 3. VRSTVA: PLOVOUCÍ TLAČÍTKA
//    var floatingActionButtons: some View {
//        VStack {
//            Spacer()
//            HStack {
//                Spacer()
//                VStack(spacing: 16) {
//                    // Tlačítko pro Navigační panel (Popelnice)
//                    Button(action: {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                            vm.showNavigationPanel.toggle()
//                        }
//                    }) {
//                        Image(systemName: "trash.fill")
//                            .foregroundStyle(vm.showNavigationPanel ? .red : .white)
//                            .font(.system(size: 18, weight: .semibold))
//                            .frame(width: 50, height: 50)
//                            .background(
//                                Circle()
//                                    .fill(vm.showNavigationPanel ? .white : .red)
//                                    .shadow(color: .black.opacity(0.15), radius: 4)
//                            )
//                    }
//
//                    // Tvoje ČERVENÉ tlačítko pro "Najdi mě"
//                    Button(action: { vm.findMe(locationManager: locationManager) }) {
//                        Image(systemName: "location.fill")
//                            .foregroundStyle(.white) // Ikona bude bílá
//                            .font(.system(size: 18, weight: .semibold))
//                            .frame(width: 50, height: 50)
//                            .background(
//                                Circle()
//                                    .fill(.red) // Tady je ta tvoje červená!
//                                    .shadow(color: .black.opacity(0.15), radius: 4)
//                            )
//                    }
//                }
//                .padding(.trailing, 20)
//                .padding(.bottom, vm.selectedStation == nil ? 40 : 320)
//            }
//        }
//        .zIndex(10)
//    }
//}
