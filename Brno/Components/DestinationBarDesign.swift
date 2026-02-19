//
//  DestinationBarDesign.swift
//  Brno
//
//  Created by Martina Kolajová on 18.02.2026.
//

import SwiftUI

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

