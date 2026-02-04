//
//  AppBackgroundView.swift
//  SummitR
//
//  Created on 2026-01-31.
//

import SwiftUI

/// Shared app background (same style as LoginView).
struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.35, blue: 0.78),
                    Color(red: 0.07, green: 0.70, blue: 0.92),
                    Color(red: 0.40, green: 0.90, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle geometric texture (wireframe feel)
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 36
                    for y in stride(from: -geo.size.height, to: geo.size.height * 2, by: step) {
                        path.move(to: CGPoint(x: -40, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width + 40, y: y + 120))
                    }
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }
}

#Preview {
    AppBackgroundView()
}

