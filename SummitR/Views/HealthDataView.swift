//
//  HealthDataView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI
import Combine

struct HealthDataView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    @State private var isVisible = false
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 与登录页、首页一致的背景
                AppBackgroundView()
                    .ignoresSafeArea()
                
                if healthKitManager.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !healthKitManager.isAuthorized {
                    AuthorizationView(healthKitManager: healthKitManager)
                } else {
                    HealthDataListView(healthKitManager: healthKitManager)
                }
            }
            .navigationTitle("健康数据")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            // 视图出现时自动刷新：已授权直接展示数据；未授权则保持授权页
            await healthKitManager.refreshForHealthTab(forceFetch: false)
        }
        .onReceive(refreshTimer) { _ in
            // 定时刷新：仅当页面可见且已授权时才刷新
            guard isVisible, healthKitManager.isAuthorized else { return }
            Task { await healthKitManager.refreshForHealthTab(forceFetch: true) }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .safeAreaInset(edge: .bottom) {
            // 为底部导航栏留出空间
            Color.clear.frame(height: 64)
        }
    }
}

// MARK: - 授权视图
struct AuthorizationView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("需要访问健康数据")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("为了展示步数、心率、活动能量、步行距离等数据，需要访问健康 App 的数据")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let errorMessage = healthKitManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await healthKitManager.requestAuthorization()
                }
            }) {
                Text("授权访问")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding()
    }
}

/// 健康数据固定展示顺序（与 HealthDataType 一致，卡片始终展示）
private let fixedHealthDataTypes: [HealthDataItem.HealthDataType] = [
    .heartRate,
    .stepCount,
    .restingHeartRate,
    .distanceWalkingRunning,
    .flightsClimbed,
    .activeEnergyBurned,
    .basalEnergyBurned,
    .dietaryEnergyConsumed
]

// MARK: - 健康数据列表（固定项平铺，无数据时显示「无数据」不隐藏卡片）
struct HealthDataListView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(fixedHealthDataTypes, id: \.self) { type in
                    HealthDataCard(
                        type: type,
                        item: healthKitManager.healthDataItems.first { $0.type == type }
                    )
                }
            }
            .padding()
        }
        .scrollBounceBehavior(.always)
        .refreshable {
            await healthKitManager.refreshForHealthTab(forceFetch: true)
        }
    }
}

// MARK: - 健康数据卡片（有数据显示数值，无数据显示「无数据」，卡片不隐藏）
struct HealthDataCard: View {
    let type: HealthDataItem.HealthDataType
    let item: HealthDataItem?
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(colorForType(type).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(colorForType(type))
            }
            
            // 数据信息
            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.headline)
                    .foregroundColor(.black)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(valueText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    if let item = item {
                        Text(item.unit)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                }
                
                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var valueText: String {
        item?.formattedValue ?? "无数据"
    }
    
    private var dateText: String {
        item.map { formatDate($0.date) } ?? "—"
    }
    
    private func colorForType(_ type: HealthDataItem.HealthDataType) -> Color {
        switch type {
        case .heartRate, .restingHeartRate: return .red
        case .stepCount, .distanceWalkingRunning: return .blue
        case .flightsClimbed: return .green
        case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed: return .orange
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    HealthDataView(healthKitManager: HealthKitManager())
}
