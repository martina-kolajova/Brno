import SwiftUI
import MapKit
import CoreLocation

// MARK: - 1. Správce polohy
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}

// MARK: - 2. Hlavní View
struct BrnoView: View {
    let allStations: [KontejnerStation]
    @StateObject private var locationManager = LocationManager()
    @StateObject private var vm = BrnoMapViewModel()
    
    @State private var streetQuery: String = "Náměstí Svobody"
    @State private var destinationAddress: String = ""
    @State private var showNavigationPanel = false
    @State private var navDestination: KontejnerStation? = nil
    
    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    ))

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $camera) {
                ForEach(allStations) { st in
                    Annotation(st.title, coordinate: st.coordinate) {
                        PiePinView(viewModel: PiePinViewModel(station: st, activeFilters: Set(KomoditaFilter.allCases)), isSelected: navDestination?.id == st.id)
                    }
                }
                
                if let userLoc = locationManager.lastLocation {
                    Annotation("Já", coordinate: userLoc.coordinate) {
                        UserLocationDot()
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                FiltersBar(selected: .constant(Set(KomoditaFilter.allCases)), streetQuery: $streetQuery) {
                    withAnimation(.spring()) { showNavigationPanel.toggle() }
                }
                .padding(.top, 12)
                
                if showNavigationPanel {
                    QuickNavButtons { filter in
                        startNavigation(for: filter)
                    }
                }
                
                Spacer()
                
                if !destinationAddress.isEmpty {
                    DestinationBarDesign(address: destinationAddress) {
                        withAnimation {
                            destinationAddress = ""
                            navDestination = nil
                        }
                    }
                    .padding(.bottom, 30)
                }
            }

            // ŠIPKA (GPS) - Teď už funkční
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: goToUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2).foregroundStyle(.white)
                            .frame(width: 56, height: 56).background(Color.red).clipShape(Circle()).shadow(radius: 4)
                    }
                    .padding(20)
                    .padding(.bottom, destinationAddress.isEmpty ? 0 : 80)
                }
            }
        }
    }

    private func goToUserLocation() {
        if let userLoc = locationManager.lastLocation {
            withAnimation(.spring()) {
                camera = .region(MKCoordinateRegion(
                    center: userLoc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
            }
        }
    }

    private func startNavigation(for filter: KomoditaFilter) {
        let start = locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 49.1951, longitude: 16.6068)
        
        if let nearest = vm.findNearest(to: start, for: filter, in: allStations) {
            withAnimation(.spring()) {
                self.navDestination = nearest
                self.destinationAddress = nearest.ulice
                self.showNavigationPanel = false
                self.camera = .region(MKCoordinateRegion(center: nearest.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
            }
        }
    }
}

// MARK: - 3. Pomocné komponenty (vložit na konec souboru)

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
                Text("Cíl: Nejbližší stanoviště").font(.caption).foregroundStyle(.gray)
            }
            Spacer()
            Button(action: onClose) { Image(systemName: "xmark.circle.fill").foregroundStyle(.gray.opacity(0.6)) }
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
                        VStack {
                            Image(systemName: filter.iconName).font(.title2)
                            Text(filter.rawValue.prefix(10) + "...").font(.caption2).fontWeight(.bold)
                        }
                        .foregroundStyle(.white).frame(width: 75, height: 75)
                        .background(filter.color).clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }.background(Color.white.opacity(0.9)).cornerRadius(20).padding(.horizontal, 16)
    }
}

// MARK: - 4. Rozšíření tvého existujícího filtru o ikony
extension KomoditaFilter {
    var iconName: String {
        switch self {
        case .papir: return "doc.text"
        case .plast: return "bottles.rack"
        case .bio: return "leaf"
        case .skloBarevne, .skloBile: return "wineglass"
        case .textil: return "tshirt"
        }
    }
}
