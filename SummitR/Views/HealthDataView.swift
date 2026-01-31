//
//  HealthDataView.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import SwiftUI

struct HealthDataView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(red: 0.95, green: 0.95, blue: 0.97)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await healthKitManager.fetchHealthData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            // 视图出现时自动刷新：已授权直接展示数据；未授权则保持授权页
            await healthKitManager.refreshForHealthTab()
        }
        .safeAreaInset(edge: .bottom) {
            // 为底部导航栏留出空间
            Color.clear.frame(height: 49)
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
            
            Text("为了展示您的心率和步数数据，需要访问健康 App 的数据")
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

// MARK: - 健康数据列表视图（瀑布流）
struct HealthDataListView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(healthKitManager.healthDataItems) { item in
                    HealthDataCard(item: item)
                }
            }
            .padding()
        }
    }
}

// MARK: - 健康数据卡片
struct HealthDataCard: View {
    let item: HealthDataItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(colorForType(item.type).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: item.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(colorForType(item.type))
            }
            
            // 数据信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.formattedValue)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(item.unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(formatDate(item.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func colorForType(_ type: HealthDataItem.HealthDataType) -> Color {
        switch type {
        case .heartRate:
            return .red
        case .stepCount:
            return .blue
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
