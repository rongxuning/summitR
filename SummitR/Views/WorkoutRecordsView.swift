//
//  WorkoutRecordsView.swift
//  SummitR
//

import SwiftUI
import HealthKit

struct WorkoutRecordsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @State private var isVisible = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()
                    .ignoresSafeArea()
                
                if healthKitManager.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !healthKitManager.isAuthorized {
                    WorkoutAuthorizationView(healthKitManager: healthKitManager)
                } else if healthKitManager.workoutRecords.isEmpty {
                    WorkoutEmptyView()
                } else {
                    WorkoutRecordsListView(records: healthKitManager.workoutRecords, healthKitManager: healthKitManager)
                }
            }
            .navigationTitle("健身记录")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await healthKitManager.refreshForWorkoutTab(forceFetch: false)
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 64)
        }
    }
}

// MARK: - 健身授权视图
struct WorkoutAuthorizationView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.35, green: 0.88, blue: 1.00))
            
            Text("需要访问健身记录")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("从系统的「健身」或「健康」App 读取您的锻炼记录，以卡片形式展示每次训练的数据")
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
                Task { await healthKitManager.requestAuthorization() }
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

// MARK: - 无记录空状态
struct WorkoutEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("暂无健身记录")
                .font(.title3)
                .fontWeight(.medium)
            Text("在「健身」或「健康」App 中记录锻炼后，会在这里显示")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 健身记录列表（卡片）
struct WorkoutRecordsListView: View {
    let records: [WorkoutRecordItem]
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(records) { record in
                    NavigationLink(destination: WorkoutDetailView(record: record, healthKitManager: healthKitManager)) {
                        WorkoutRecordCard(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .scrollBounceBehavior(.always)
        .refreshable {
            await healthKitManager.refreshForWorkoutTab(forceFetch: true)
        }
    }
}

// MARK: - 单条健身记录卡片
struct WorkoutRecordCard: View {
    let record: WorkoutRecordItem
    
    private let cardBackground = Color.white
    private let accentColor = Color(red: 0.35, green: 0.88, blue: 1.00)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行：运动类型 + 日期
            HStack {
                Image(systemName: iconForActivity(record.activityType))
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
                Text(record.activityTypeName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(record.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 时间段
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(record.timeRangeFormatted)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            
            // 时长
            HStack {
                Label(record.durationFormatted, systemImage: "timer")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            
            // 能量 / 距离（若有）
            if record.energyFormatted != nil || record.distanceFormatted != nil {
                HStack(spacing: 16) {
                    if let energy = record.energyFormatted {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                            Text(energy)
                                .font(.subheadline)
                        }
                        .foregroundColor(.orange)
                    }
                    if let distance = record.distanceFormatted {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                            Text(distance)
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // 来源（若有）
            if let source = record.sourceName, !source.isEmpty {
                Text("来源：\(source)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func iconForActivity(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .hiking: return "figure.hiking"
        default: return "figure.run"
        }
    }
}

#Preview {
    WorkoutRecordsView(healthKitManager: HealthKitManager())
}
