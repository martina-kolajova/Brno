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

// MARK: - 3. Hlavné View
struct BrnoView: View {
    let allStations: [KontejnerStation]
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()
    @StateObject private var vm = BrnoMapViewModel()
    
    // Filtry a hledání
    @State private var streetQuery: String = ""
    @State private var selectedFilters: Set<KomoditaFilter> = Set(KomoditaFilter.allCases)
    @FocusState private var isSearchFocused: Bool
    
    // Navigace a stavy
    @State private var showNavigationPanel = false
    @State private var selectedStation: KontejnerStation? = nil
    @State private var route: MKRoute? = nil
    @State private var routeDistance: String = ""
    @State private var routeTravelTime: String = ""
    @State private var activeSearchPoint: CLLocationCoordinate2D? = nil

    // KAMERA A REGION
    @State private var camera: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )))
    
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. VRSTVA: MAPA
            Map(position: $camera) {
                ForEach(allStations.filter { station in
                    selectedFilters.isEmpty || selectedFilters.contains { filter in station.matches(filter) }
                }) { st in
                    let zoomScale = max(0.5, min(1.1, 0.02 / mapRegion.span.latitudeDelta))
                    let isSelected = selectedStation?.id == st.id
                    
                    Annotation(st.ulice, coordinate: st.coordinate) {
                        PiePinView(
                            viewModel: PiePinViewModel(station: st, activeFilters: selectedFilters),
                            isSelected: isSelected
                        )
                        .scaleEffect(isSelected ? 0.9 : zoomScale)
                        .onTapGesture {
                            withAnimation(.spring()) { selectStation(st) }
                        }
                    }
                }
                
                if let searchPoint = activeSearchPoint {
                    Annotation("Východzí bod", coordinate: searchPoint) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title).foregroundStyle(.red).background(Circle().fill(.white)).shadow(radius: 3)
                    }
                }
                
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
                
                UserAnnotation()
            }
            .onMapCameraChange { context in mapRegion = context.region }
            .ignoresSafeArea()

            // 2. VRSTVA: HORNÍ LIŠTA A PANEL
            VStack(spacing: 0) {
                FiltersBar(selected: $selectedFilters, streetQuery: $streetQuery)
                    .focused($isSearchFocused)
                    .padding(.top, 10)
                
                if isSearchFocused && !searchCompleter.results.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchCompleter.results, id: \.self) { result in
                                Button { selectRealAddress(result) } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title).foregroundStyle(.red)
                                        Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                                    }
                                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(Color(.systemBackground)).cornerRadius(15).shadow(radius: 5).padding(.horizontal, 20).padding(.top, 5)
                    .frame(maxHeight: 200)
                }

                if showNavigationPanel {
                    QuickNavButtons { filter in startQuickNavigation(for: filter) }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 10)
                }
                Spacer()
            }
//
//    // Detail stanice
            if let station = selectedStation {
                VStack(spacing: 0) {
                    // Tady už není ta malá bublina, hned následuje panel:
                    DetailStationPanel(
                        station: station,
                        navInfo: routeDistance.isEmpty ? nil : "\(routeDistance) • \(routeTravelTime)",
                        onNavigate: { calculateRoute(to: station.coordinate) },
                        onClose: {
                            withAnimation {
                                selectedStation = nil
                                route = nil
                                routeDistance = ""
                                routeTravelTime = ""
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
            }

            // 4. VRSTVA: PLOVOUCÍ TLAČÍTKA (PŘESNĚ SEM!)
            // Tlačítka v pravém dolním rohu
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 16) {

                        // 1️⃣ TLAČÍTKO (Kontejner / Navigace)
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showNavigationPanel.toggle()
                            }
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(showNavigationPanel ? .red : .white)   // 🔁 reversed correctly
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(showNavigationPanel ? .white : .red)      // 🔁 reversed correctly
                                        .shadow(color: .black.opacity(0.15), radius: 4)
                                )
                        }
                        .scaleEffect(showNavigationPanel ? 0.95 : 1.0)

                        // 2️⃣ ČERVENÉ TLAČÍTKO (Moje poloha)
                        Button(action: findMe) {
                            Image(systemName: "location.fill")
                        }
                        .buttonStyle(MagneticButtonStyle(isActive: false)) // independent style

                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, selectedStation == nil ? 40 : 320)
                }
            }
            .zIndex(10) // EXTRÉMNĚ DŮLEŽITÉ - dává tlačítka nad mapu
        }
        .onChange(of: streetQuery) { newValue in
            if isSearchFocused { searchCompleter.update(query: newValue) }
        }
    }

    // --- LOGIKA ---
    private func findMe() {
        guard let userLoc = locationManager.lastLocation else { return }
        activeSearchPoint = nil
        withAnimation(.spring()) {
            camera = .region(MKCoordinateRegion(center: userLoc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        }
    }

    private func selectRealAddress(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            activeSearchPoint = coordinate
            streetQuery = completion.title
            isSearchFocused = false
            withAnimation(.spring()) {
                camera = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
            }
        }
    }

    private func selectStation(_ st: KontejnerStation) {
        withAnimation(.spring()) {
            selectedStation = st
            route = nil
            routeDistance = ""
            isSearchFocused = false
        }
    }

    private func startQuickNavigation(for filter: KomoditaFilter) {
        let basePoint = activeSearchPoint ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
        if let nearest = vm.findNearest(to: basePoint, for: filter, in: allStations) {
            selectStation(nearest)
            showNavigationPanel = false
        }
    }

    private func calculateRoute(to destination: CLLocationCoordinate2D) {
        let startPoint = activeSearchPoint ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPoint))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                if let computedRoute = response.routes.first {
                    await MainActor.run {
                        withAnimation(.spring()) {
                            self.route = computedRoute
                            let dist = computedRoute.distance
                            self.routeDistance = dist < 1000 ? "\(Int(dist)) m" : String(format: "%.1f km", dist / 1000)
                            let minutes = Int(computedRoute.expectedTravelTime / 60)
                            self.routeTravelTime = "\(minutes) min"
                            self.camera = .rect(computedRoute.polyline.boundingMapRect.insetBy(dx: -200, dy: -200))
                        }
                    }
                }
            } catch { print(error.localizedDescription) }
        }
    }
}
// MARK: - Pomocné komponenty (beze změny)
struct UserLocationDot: View {
    var body: some View {
        ZStack {
            Circle().fill(.red.opacity(0.2)).frame(width: 30, height: 30)
            Circle().stroke(.white, lineWidth: 2).frame(width: 14, height: 14)
            Circle().fill(.red).frame(width: 10, height: 10)
        }
    }
}

struct DestinationBarDesign: View {
    let address: String
    let onClose: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "flag.checkered").foregroundStyle(.red).padding(.leading, 8)
            VStack(alignment: .leading) {
                Text(address).font(.system(size: 16, weight: .bold))
                Text("Nejbližší stanoviště").font(.caption).foregroundStyle(.gray)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.gray.opacity(0.6)).font(.title2)
            }
        }
        .padding().background(Color.white).cornerRadius(20).shadow(radius: 5).padding(.horizontal, 16)
    }
}

struct QuickNavButtons: View {
    var onSelect: (KomoditaFilter) -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(KomoditaFilter.allCases) { filter in
                    Button { onSelect(filter) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: filter.iconName).font(.title3)
                            Text(filter.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white).frame(width: 70, height: 70)
                        .background(filter.color).clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .background(Color.white.opacity(0.95)).cornerRadius(20).padding(.horizontal, 16)
    }
}

//// MARK: - 1. Správca polohy
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private let manager = CLLocationManager()
//    @Published var lastLocation: CLLocation?
//    @Published var currentStreetName: String = ""
//
//    override init() {
//        super.init()
//        manager.delegate = self
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.requestWhenInUseAuthorization()
//        manager.startUpdatingLocation()
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        self.lastLocation = location
//        
//        let geocoder = CLGeocoder()
//        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
//            if let street = placemarks?.first?.thoroughfare {
//                DispatchQueue.main.async { self.currentStreetName = street }
//            }
//        }
//    }
//}
//
//// MARK: - 2. Našepkávač všetkých ulíc
//class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
//    @Published var results: [MKLocalSearchCompletion] = []
//    private var completer = MKLocalSearchCompleter()
//    
//    override init() {
//        super.init()
//        completer.delegate = self
//        completer.region = MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//        )
//        completer.resultTypes = .address
//    }
//    
//    func update(query: String) { completer.queryFragment = query }
//    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
//        self.results = completer.results.filter { $0.subtitle.contains("Brno") }
//    }
//}
//
//
//// MARK: - 3. Hlavné View
//import SwiftUI
//import MapKit
//
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
//    @State private var camera: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
//        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//    )))
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            Map(position: $camera) {
//                // 1. Filtrované stanice
//                ForEach(allStations.filter { station in
//                    // Pokud jsou filtry prázdné, vrátíme 'true' (ukážeme vše)
//                    // Jinak zkontrolujeme, jestli stanice odpovídá aspoň jednomu filtru
//                    selectedFilters.isEmpty || selectedFilters.contains { filter in station.matches(filter) }
//                }) { st in
//                    Annotation(st.ulice, coordinate: st.coordinate) {
//                        PiePinView(
//                            viewModel: PiePinViewModel(station: st, activeFilters: selectedFilters),
//                            isSelected: selectedStation?.id == st.id
//                        )
//                        .onTapGesture {
//                            withAnimation(.spring()) {
//                                selectStation(st)
//                            }
//                        }
//                    }
//                }
//                
//                // 2. Východzí bod (červený špendlík po hledání)
//                if let searchPoint = activeSearchPoint {
//                    Annotation("Východzí bod", coordinate: searchPoint) {
//                        Image(systemName: "mappin.circle.fill")
//                            .font(.title)
//                            .foregroundStyle(.red)
//                            .background(Circle().fill(.white))
//                            // Přidáme stín, aby špendlík na mapě "seděl"
//                            .shadow(radius: 3)
//                    }
//                }
//                
//                // 3. Trasa navigace
//                if let route {
//                    MapPolyline(route.polyline)
//                        .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
//                }
//                
//                // 4. Moje poloha (modrá tečka)
//                UserAnnotation()
//            }
//            .ignoresSafeArea()
//
//            // JEDNOTNÁ LIŠTA (Nový Layout)
//            VStack(spacing: 0) {
//                // V BrnoView.swift (kolem řádku 114)
//                // V BrnoView.swift u volání FiltersBar:
//                FiltersBar(
//                    selected: $selectedFilters,
//                    streetQuery: $streetQuery,
//                    onQuickNavTap: { // Přejmenováno z onPlusTap na onQuickNavTap
//                        withAnimation(.spring()) {
//                            showNavigationPanel.toggle()
//                        }
//                    }
//                )
//                .focused($isSearchFocused)
//                .padding(.top, 10)
//                
//                // Našeptávač ulic
//                if isSearchFocused && !searchCompleter.results.isEmpty {
//                    VStack(spacing: 0) {
//                        ScrollView {
//                            VStack(alignment: .leading, spacing: 0) {
//                                ForEach(searchCompleter.results, id: \.self) { result in
//                                    Button { selectRealAddress(result) } label: {
//                                        VStack(alignment: .leading, spacing: 2) {
//                                            Text(result.title).foregroundStyle(.red)
//                                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
//                                        }
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .padding(12)
//                                    }
//                                    Divider().padding(.horizontal, 16)
//                                }
//                            }
//                        }
//                        .frame(maxHeight: 200)
//                    }
//                    .background(Color(.systemBackground)).cornerRadius(15).shadow(radius: 5).padding(.horizontal, 20).padding(.top, 5)
//                }
//
//                // Panel rychlé navigace (vyjíždí pod lištou)
//                if showNavigationPanel {
//                    QuickNavButtons { filter in startQuickNavigation(for: filter) }
//                        .transition(.move(edge: .top).combined(with: .opacity))
//                        .padding(.top, 10)
//                }
//                Spacer()
//            }
//
//            // Detail stanice
//            if let station = selectedStation {
//                VStack(spacing: 0) {
//                    if !routeDistance.isEmpty {
//                        HStack {
//                            Image(systemName: "figure.walk")
//                            Text("\(routeDistance) • \(routeTravelTime)")
//                                .fontWeight(.bold)
//                        }
//                        .padding(.vertical, 8).padding(.horizontal, 16)
//                        .background(Color(.systemBackground)).cornerRadius(20).shadow(radius: 2)
//                        .padding(.bottom, -10).zIndex(1)
//                    }
//                    
//                    DetailStationPanel(
//                            station: station,
//                            // Tady spojíme vzdálenost a čas do jednoho textu pro panel
//                            navInfo: routeDistance.isEmpty ? nil : "\(routeDistance) • \(routeTravelTime)",
//                            onNavigate: { calculateRoute(to: station.coordinate) },
//                            onClose: {
//                                withAnimation {
//                                    selectedStation = nil
//                                    route = nil
//                                    routeDistance = ""
//                                    routeTravelTime = ""
//                                }
//                            }
//                        )
//                        .transition(.move(edge: .bottom))
//                        .zIndex(2) // Aby byl panel vždy nahoře
//                    }
//            }
//
//            // GPS Tlačítko
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Button(action: findMe) {
//                        Image(systemName: "location.fill").font(.title2).foregroundStyle(.white)
//                            .frame(width: 56, height: 56).background(Color.red).clipShape(Circle()).shadow(radius: 4)
//                    }
//                    .padding(20).padding(.bottom, selectedStation == nil ? 20 : 260)
//                }
//            }
//        }
//        .onChange(of: streetQuery) { newValue in
//            if isSearchFocused { searchCompleter.update(query: newValue) }
//        }
//    }
//
//    // --- LOGIKA ---
//
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
//        
//        search.start { response, _ in
//            // OPRAVA CHYBY ZE SCREENSHOTU: .placemark.coordinate
//            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
//            
//            activeSearchPoint = coordinate
//            streetQuery = completion.title
//            isSearchFocused = false
//            
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
//            routeTravelTime = ""
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
//                            let dist = computedRoute.distance
//                            self.routeDistance = dist < 1000 ? "\(Int(dist)) m" : String(format: "%.1f km", dist / 1000)
//                            // NAHRAĎ JE TÍMTO:
//                            let formatter = DateComponentsFormatter()
//                            formatter.allowedUnits = [.minute]
//                            formatter.unitsStyle = .short // Změní "minutes" na "min"
//                            // Pokud chceš vyloženě české slovo "minut", nejlepší je unitsStyle .short
//                            // nebo si to nadefinovat ručně, aby to nebylo závislé na jazyku simulátoru:
//
//                            let minutes = Int(computedRoute.expectedTravelTime / 60)
//                            self.routeTravelTime = "\(minutes) min"
//                            self.routeTravelTime = formatter.string(from: computedRoute.expectedTravelTime) ?? ""
//                            self.camera = .rect(computedRoute.polyline.boundingMapRect.insetBy(dx: -200, dy: -200))
//                        }
//                    }
//                }
//            } catch { print(error.localizedDescription) }
//        }
//    }
//}
//// MARK: - Pomocné komponenty
//
//struct UserLocationDot: View {
//    var body: some View {
//        ZStack {
//            Circle().fill(.red.opacity(0.2)).frame(width: 30, height: 30)
//            Circle().stroke(.white, lineWidth: 2).frame(width: 14, height: 14)
//            Circle().fill(.red).frame(width: 10, height: 10)
//        }
//    }
//}
//
//struct DestinationBarDesign: View {
//    let address: String
//    let onClose: () -> Void
//    var body: some View {
//        HStack {
//            Image(systemName: "flag.checkered").foregroundStyle(.red).padding(.leading, 8)
//            VStack(alignment: .leading) {
//                Text(address).font(.system(size: 16, weight: .bold))
//                Text("Nejbližší stanoviště").font(.caption).foregroundStyle(.gray)
//            }
//            Spacer()
//            Button(action: onClose) {
//                Image(systemName: "xmark.circle.fill").foregroundStyle(.gray.opacity(0.6)).font(.title2)
//            }
//        }
//        .padding().background(Color.white).cornerRadius(20).shadow(radius: 5).padding(.horizontal, 16)
//    }
//}
//
//struct QuickNavButtons: View {
//    var onSelect: (KomoditaFilter) -> Void
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(KomoditaFilter.allCases) { filter in
//                    Button { onSelect(filter) } label: {
//                        VStack(spacing: 4) {
//                            Image(systemName: filter.iconName).font(.title3)
//                            Text(filter.displayName)
//                                .font(.system(size: 10, weight: .bold))
//                                .lineLimit(1)
//                        }
//                        .foregroundStyle(.white).frame(width: 70, height: 70)
//                        .background(filter.color).clipShape(RoundedRectangle(cornerRadius: 15))
//                    }
//                }
//            }
//            .padding(.horizontal, 16).padding(.vertical, 8)
//        }
//        .background(Color.white.opacity(0.95)).cornerRadius(20).padding(.horizontal, 16)
//    }
//}
//
////// MARK: - Preview
////#Preview {
////    BrnoView(allStations: [
////        KontejnerStation(
////            id: "1",
////            title: "Náměstí Svobody 1",
////            ulice: "Náměstí Svobody",
////            cp: "1", // Přidej konkrétní číslo nebo nil
////            komodity: ["Papír", "Plasty, nápojové kartony a hliníkové plechovky od nápojů"],
////            coordinate: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
////        )
////    ])
////}
