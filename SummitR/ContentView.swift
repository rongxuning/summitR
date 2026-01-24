//
//  ContentView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页封面
            HomeCoverView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            // 健康数据
            HealthDataView()
                .tabItem {
                    Label("健康", systemImage: "heart.fill")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
