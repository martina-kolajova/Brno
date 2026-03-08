//
//  MapActionButtons.swift
//  Brno
//
//  Floating action buttons for the map screen.
//  Stop navigation (X), find nearest (trash), and locate me (arrow).
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - Map Action Buttons

/// Floating action buttons (FABs) displayed on the bottom-right of the map.
struct MapActionButtons: View {
    @ObservedObject var vm: BrnoMapViewModel
    let isInBrno: Bool
    let effectiveLocation: CLLocation
    let onClearSearch: () -> Void

    private var bottomPadding: CGFloat {
        guard vm.selectedStation != nil else { return 40 }
        switch vm.detent {
        case .height(70):     return 90
        case .fraction(0.37): return 320
        case .large:          return 680
        default:              return 320
        }
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    stopButton
                    trashButton
                    locationButton
                }
                .padding(.trailing, 20)
                .padding(.bottom, bottomPadding)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.detent)
        .animation(.spring(response: 0.35), value: vm.isNavigating)
        .animation(.spring(response: 0.35), value: vm.selectedStation == nil)
        .zIndex(10)
    }

    // MARK: - Zoom Out

    private var stopButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.4)) {
                // If navigating, stop navigation and clear everything.
                if vm.isNavigating {
                    vm.stopNavigation()
                    onClearSearch()
                } else {
                    // Otherwise just zoom out to the default Brno overview.
                    vm.camera = .region(MKCoordinateRegion(
                        center: LocationManager.defaultBrnoCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
        } label: {
            Image(systemName: "minus.magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.red))
                .shadow(color: .black.opacity(0.15), radius: 4)
        }
    }

    // MARK: - Find Nearest (Trash)

    private var trashButton: some View {
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
    }

    // MARK: - Locate Me

    private var locationButton: some View {
        Button {
            // Clear any street search — go back to GPS / default location
            vm.clearSearchPoint()
            onClearSearch()

            // Move camera to user's location (or Brno centre if not in Brno)
            let coord = isInBrno
                ? effectiveLocation.coordinate
                : LocationManager.defaultBrnoCoordinate
            withAnimation(.spring()) {
                vm.camera = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        } label: {
            // Arrow button — always red background, white icon. No toggle.
            Image(systemName: "location.fill")
                .foregroundStyle(.white)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.red)
                        .shadow(color: .black.opacity(0.15), radius: 4)
                )
        }
    }
}
