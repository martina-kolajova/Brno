//
//  MenuView.swift
//  Brno
//
//  Created by Martina Kolajová on 04.02.2026.
//
import SwiftUI

enum MenuDestination {
    case map
    case education
    case about
}

struct MenuView: View {

    var onSelect: (MenuDestination) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - HEADER
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bordel")
                        .font(.system(size: 34, weight: .black))
                    Text("Brno")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.red)
                }
                .padding(.top, 40)

                Divider()

                MenuItem(
                    title: "Mapa kontejnerů",
                    subtitle: "Najdi kam to hodit",
                    icon: "map.fill"
                ) {
                    onSelect(.map)
                }

                MenuItem(
                    title: "Jak třídit",
                    subtitle: "Edukační přehled",
                    icon: "leaf.fill"
                ) {
                    onSelect(.education)
                }

                MenuItem(
                    title: "O aplikaci",
                    subtitle: "Open data Brno",
                    icon: "info.circle.fill"
                ) {
                    onSelect(.about)
                }

                Spacer()

                Text("data.brno.cz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 300)
            .background(
                Color.white.shadow(radius: 20)
            )

            Spacer()
        }
        .ignoresSafeArea()
    }
}
struct MenuItem: View {

    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.black)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuView { destination in
        print("Selected:", destination)
    }
}
