//
//  ContentView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var healthKitManager = HealthKitManager()
    @Environment(\.scenePhase) private var scenePhase
    
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
                
                // 自定义底部导航栏：
                // - SwiftUI 默认只对齐到“安全区底部”，会导致不吸底
                // - 这里向下偏移覆盖 safe area，并允许绘制到屏幕最底部
                CustomTabBar(selectedTab: $selectedTab, tabs: tabs, safeAreaBottom: geometry.safeAreaInsets.bottom)
                    .padding(.bottom, -geometry.safeAreaInsets.bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) { _, newValue in
            // 每次切到“健康”tab 自动检查/刷新
            guard newValue == 1 else { return }
            Task { await healthKitManager.refreshForHealthTab(forceFetch: true) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // 回到前台时，如果当前在健康页，也拉一次最新
            guard newPhase == .active, selectedTab == 1 else { return }
            Task { await healthKitManager.refreshForHealthTab(forceFetch: true) }
        }
    }
}

// MARK: - 自定义底部导航栏
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(title: String, icon: String, selectedIcon: String)]
    let safeAreaBottom: CGFloat
    
    // 深蓝底 + 天蓝高亮（小红书风格偏深色版）
    private let barBackground = Color(red: 0.03, green: 0.14, blue: 0.30)
    private let selectedColor = Color(red: 0.35, green: 0.88, blue: 1.00)
    private let unselectedColor = Color.white.opacity(0.72)
    
    // 标准 tab bar 内容高度（图标/文字都居中在这 49pt 内）
    private let contentHeight: CGFloat = 49
    
    // 两个 tab 作为一组在导航栏内水平居中时的间距与单 tab 宽度
    private let tabSpacing: CGFloat = 56
    private let tabItemWidth: CGFloat = 88
    
    var body: some View {
        VStack(spacing: 0) {
            // 首页、健康 作为一组在深色导航栏内水平居中
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: tabSpacing) {
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
                                    .scaleEffect(selectedTab == index ? 1.06 : 1.0)
                                    .frame(width: 30, height: 28)
                                
                                Text(tabs[index].title)
                                    .font(.system(size: 11, weight: selectedTab == index ? .semibold : .regular))
                                    .foregroundColor(selectedTab == index ? selectedColor : unselectedColor)
                            }
                            .frame(width: tabItemWidth, height: contentHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(height: contentHeight)
            
            // 让背景覆盖到屏幕底部，但内容仍在 49pt 内居中
            Color.clear.frame(height: max(0, safeAreaBottom))
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // 深蓝背景
                barBackground
                
                // 顶部边框
                VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.white.opacity(0.12))
                    Spacer()
                }
            }
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: -4)
    }
}

#Preview {
    ContentView()
}
