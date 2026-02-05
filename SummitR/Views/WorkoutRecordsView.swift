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
                        .foregroundColor(.black)
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
                .foregroundColor(.black)
            
            Text("需要访问健身记录")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("从系统的「健身」或「健康」App 读取您的锻炼记录，以卡片形式展示每次训练的数据")
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let errorMessage = healthKitManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.black)
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
                .foregroundColor(.black)
            Text("暂无健身记录")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.black)
            Text("在「健身」或「健康」App 中记录锻炼后，会在这里显示")
                .font(.subheadline)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 用于根据滚动位置计算「当前顶部」记录
private struct WorkoutRowMinYKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] { [:] }
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, n in n }
    }
}

private func workoutYearMonthString(from date: Date) -> String {
    let cal = Calendar.current
    let y = cal.component(.year, from: date)
    let m = cal.component(.month, from: date)
    return String(format: "%d年%02d月", y, m)
}

// MARK: - 健身记录列表（卡片，支持滚动加载更多，左上角悬浮年月）
struct WorkoutRecordsListView: View {
    let records: [WorkoutRecordItem]
    @ObservedObject var healthKitManager: HealthKitManager
    /// 当前位于屏幕顶部区域的记录对应的年月（用于左上角悬浮展示）
    @State private var topYearMonth: String?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(records) { record in
                        rowContent(record: record)
                    }
                    if healthKitManager.workoutLoadingMore {
                        HStack {
                            ProgressView()
                            Text("加载更多...")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
                .padding()
            }
            .coordinateSpace(name: "workoutScroll")
            .scrollBounceBehavior(.always)
            .refreshable {
                await healthKitManager.refreshForWorkoutTab(forceFetch: true)
            }
            .onPreferenceChange(WorkoutRowMinYKey.self) { minYs in
                updateTopYearMonth(from: minYs)
            }
            .onAppear {
                if let first = records.first {
                    topYearMonth = workoutYearMonthString(from: first.startDate)
                }
            }
            .onChange(of: records.count) { _, _ in
                if topYearMonth == nil, let first = records.first {
                    topYearMonth = workoutYearMonthString(from: first.startDate)
                }
            }
            
            if let yearMonth = topYearMonth {
                Text(yearMonth)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
    }
    
    @ViewBuilder
    private func rowContent(record: WorkoutRecordItem) -> some View {
        NavigationLink(destination: WorkoutDetailView(record: record, healthKitManager: healthKitManager)) {
            WorkoutRecordCard(record: record)
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { g in
                Color.clear.preference(
                    key: WorkoutRowMinYKey.self,
                    value: [record.id: g.frame(in: .named("workoutScroll")).minY]
                )
            }
        )
        .onAppear {
            if record.id == records.last?.id {
                Task { await healthKitManager.loadMoreWorkouts() }
            }
        }
    }
    
    private func updateTopYearMonth(from minYs: [UUID: CGFloat]) {
        guard !records.isEmpty else { return }
        let topThreshold: CGFloat = 140
        let visible = minYs.filter { $0.value <= topThreshold }
        guard let topId = visible.max(by: { $0.value < $1.value })?.key else { return }
        guard let record = records.first(where: { $0.id == topId }) else { return }
        topYearMonth = workoutYearMonthString(from: record.startDate)
    }
}

// MARK: - 单条健身记录卡片
struct WorkoutRecordCard: View {
    let record: WorkoutRecordItem
    
    private let cardBackground = Color.white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行：运动类型 + 日期
            HStack {
                Image(systemName: iconForActivity(record.activityType))
                    .font(.system(size: 22))
                    .foregroundColor(.black)
                Text(record.activityTypeName)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Text(record.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.black)
            }
            
            // 时间段
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(record.timeRangeFormatted)
                    .font(.subheadline)
            }
            .foregroundColor(.black)
            
            // 时长
            HStack {
                Label(record.durationFormatted, systemImage: "timer")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.black)
            
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
                        .foregroundColor(.black)
                    }
                    if let distance = record.distanceFormatted {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                            Text(distance)
                                .font(.subheadline)
                        }
                        .foregroundColor(.black)
                    }
                }
            }
            
            // 来源（若有）
            if let source = record.sourceName, !source.isEmpty {
                Text("来源：\(source)")
                    .font(.caption2)
                    .foregroundColor(.black)
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
