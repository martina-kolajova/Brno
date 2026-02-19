//
//  UserLocationDot.swift
//  Brno
//
//  Created by Martina Kolajová on 18.02.2026.
//
import SwiftUI

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
