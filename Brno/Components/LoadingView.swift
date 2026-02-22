//
//  LoadingView.swift
//  Brno
//
//  Created by Martina Kolajová on 04.02.2026.
//

import SwiftUI



struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack {
            Image(systemName: "arrow.3.trianglepath")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(.red)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}
