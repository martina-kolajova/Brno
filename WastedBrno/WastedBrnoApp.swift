//
//  BrnoApp.swift
//  Brno
//
//  Created by Martina Kolajová on 27.01.2026.
//

import SwiftUI
import os

@main
struct WastedBrnoApp: App {

    private let logger = Logger(subsystem: "com.app.brno", category: "AppLifecycle")

    init() {
        logger.info("🚀 App launched")
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

