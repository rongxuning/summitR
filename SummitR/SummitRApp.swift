//
//  SummitRApp.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

@main
struct SummitRApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppBackgroundView()
                    .ignoresSafeArea()
                ContentView()
            }
        }
    }
}
