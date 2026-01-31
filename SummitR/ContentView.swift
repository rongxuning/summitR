//
//  ContentView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var healthKitManager = HealthKitManager()
    
    // Tab 配置
    private let tabs: [(title: String, icon: String, selectedIcon: String)] = [
        ("首页", "house", "house.fill"),
        ("健康", "heart", "heart.fill")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 内容区域
                Group {
                    switch selectedTab {
                    case 0:
                        HomeCoverView()
                    case 1:
                        HealthDataView(healthKitManager: healthKitManager)
                    default:
                        HomeCoverView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // 自定义底部导航栏（紧贴底部，包含安全区域）
                CustomTabBar(selectedTab: $selectedTab, tabs: tabs, safeAreaBottom: geometry.safeAreaInsets.bottom)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) { _, newValue in
            // 每次切到“健康”tab 自动检查/刷新
            guard newValue == 1 else { return }
            Task { await healthKitManager.refreshForHealthTab() }
        }
    }
}

// MARK: - 自定义底部导航栏
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(title: String, icon: String, selectedIcon: String)]
    let safeAreaBottom: CGFloat
    
    // 天蓝色
    private let selectedColor = Color(red: 0.0, green: 0.7, blue: 1.0)
    private let unselectedColor = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    // 标准tab bar内容高度
    private let contentHeight: CGFloat = 49
    
    // 总高度：内容高度 + 安全区域（略往上一点，减少约2-4pt）
    private var totalHeight: CGFloat {
        contentHeight + max(0, safeAreaBottom - 3)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                            .font(.system(size: 24, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? selectedColor : unselectedColor)
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                        
                        Text(tabs[index].title)
                            .font(.system(size: 11, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? selectedColor : unselectedColor)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity) // 在整个导航栏高度内居中
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: totalHeight)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // 白色背景
                Color.white
                
                // 顶部边框
                VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                    Spacer()
                }
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -2)
    }
}

#Preview {
    ContentView()
}
