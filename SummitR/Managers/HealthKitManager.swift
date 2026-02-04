//
//  HealthKitManager.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import Foundation
import HealthKit
import Combine
import SwiftUI

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var healthDataItems: [HealthDataItem] = []
    @Published var workoutRecords: [WorkoutRecordItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 简单节流：避免频繁切换 tab 导致重复请求
    private var lastFetchAt: Date?
    private var lastWorkoutFetchAt: Date?
    private var currentFetchTask: Task<Void, Never>?
    private var currentWorkoutFetchTask: Task<Void, Never>?
    
    // 需要请求的权限（心率、步数、健身记录）
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.workoutType()
    ]
    
    init() {
        // 不在 init 里强判授权；由页面出现时统一 refresh
    }
    
    // MARK: - Public lifecycle helpers
    
    /// 每次进入“健康”页面/Tab 时调用：
    /// - 如果系统认为不需要再弹窗授权，则直接尝试拉取数据（已授权 -> 直接展示）
    /// - 如果需要授权弹窗，则保持未授权状态（让用户点按钮）
    /// - forceFetch=true：每次进入都强制拉最新（推荐用于 tab 切换触发）
    func refreshForHealthTab(forceFetch: Bool = false) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 HealthKit"
            isAuthorized = false
            return
        }
        
        errorMessage = nil
        
        let status = await requestStatusForAuthorization()
        switch status {
        case .unnecessary:
            // 系统判断不需要再请求（用户已做过选择）。此时直接尝试读取来驱动 UI。
            isAuthorized = true
            await fetchLatestIfNeeded(force: forceFetch)
        case .shouldRequest:
            // 仍需要请求授权（首次/新增类型）
            isAuthorized = false
        case .unknown:
            // 不确定时，保守处理：不自动弹授权，让用户手动点
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    private func fetchLatestIfNeeded(force: Bool) async {
        // 取消上一次未完成的拉取（避免并发覆盖/浪费）
        currentFetchTask?.cancel()
        
        // 节流：非强制情况下，3 秒内不重复拉取
        if !force, let lastFetchAt {
            if Date().timeIntervalSince(lastFetchAt) < 3 {
                return
            }
        }
        
        lastFetchAt = Date()
        currentFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchHealthData()
        }
        
        // 等待本次拉取结束（让 UI 更确定地更新）
        await currentFetchTask?.value
    }
    
    private func requestStatusForAuthorization() async -> HKAuthorizationRequestStatus {
        await withCheckedContinuation { continuation in
            healthStore.getRequestStatusForAuthorization(
                toShare: Set<HKSampleType>(),
                read: readTypes
            ) { status, _ in
                continuation.resume(returning: status)
            }
        }
    }
    
    // 检查授权状态
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 HealthKit"
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        let stepCountStatus = healthStore.authorizationStatus(for: stepCountType)
        
        // 注意：对于只读权限，authorizationStatus 可能不准确
        // 状态 1 (.sharingDenied) 可能不意味着真正的拒绝
        // 实际应该通过尝试读取数据来判断
        
        // 只要不是明确拒绝，就认为可以尝试访问
        // 真正的授权状态需要通过实际读取数据来验证
        let heartRateAuthorized = heartRateStatus != .sharingDenied
        let stepCountAuthorized = stepCountStatus != .sharingDenied
        
        // 对于只读权限，只要不是明确拒绝，就允许尝试
        isAuthorized = heartRateAuthorized && stepCountAuthorized
    }
    
    // 请求授权
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 HealthKit"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes)
            
            // 等待一小段时间，让系统更新授权状态
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 授权后刷新一次
            await refreshForHealthTab(forceFetch: true)
        } catch {
            errorMessage = "授权请求失败: \(error.localizedDescription)"
            isAuthorized = false
        }
        
        isLoading = false
    }
    
    // 获取健康数据
    func fetchHealthData() async {
        guard isAuthorized else { return }
        
        isLoading = true
        errorMessage = nil
        
        var items: [HealthDataItem] = []
        
        let hr = await fetchHeartRateResult()
        if hr.authorizationDenied {
            isAuthorized = false
            errorMessage = "未获得读取心率权限，请在 健康 > 头像/隐私 > 应用 中允许 SummitR 读取心率"
        } else if let item = hr.item {
            items.append(item)
        }
        
        let steps = await fetchStepCountResult()
        if steps.authorizationDenied {
            isAuthorized = false
            errorMessage = "未获得读取步数权限，请在 健康 > 头像/隐私 > 应用 中允许 SummitR 读取步数"
        } else if let item = steps.item {
            items.append(item)
        }
        
        healthDataItems = items.sorted { $0.date > $1.date }
        isLoading = false
    }
    
    // MARK: - 健身记录
    
    /// 进入「健身记录」tab 时调用
    func refreshForWorkoutTab(forceFetch: Bool = false) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 HealthKit"
            isAuthorized = false
            return
        }
        errorMessage = nil
        let status = await requestStatusForAuthorization()
        switch status {
        case .unnecessary:
            isAuthorized = true
            await fetchWorkoutsIfNeeded(force: forceFetch)
        case .shouldRequest:
            isAuthorized = false
        case .unknown, _:
            isAuthorized = false
        }
    }
    
    private func fetchWorkoutsIfNeeded(force: Bool) async {
        currentWorkoutFetchTask?.cancel()
        if !force, let last = lastWorkoutFetchAt, Date().timeIntervalSince(last) < 3 {
            return
        }
        lastWorkoutFetchAt = Date()
        currentWorkoutFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchWorkouts()
        }
        await currentWorkoutFetchTask?.value
    }
    
    /// 拉取系统健身 App 的锻炼记录（最近 90 天）
    func fetchWorkouts() async {
        guard isAuthorized else { return }
        currentWorkoutFetchTask?.cancel()
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -90, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                Task { @MainActor in
                    if let error = error {
                        let nsError = error as NSError
                        if nsError.domain == HKErrorDomain, nsError.code == HKError.errorAuthorizationDenied.rawValue {
                            self?.isAuthorized = false
                            self?.errorMessage = "未获得读取健身记录权限，请在 健康 > 应用 中允许 SummitR 读取体能训练"
                        } else {
                            self?.errorMessage = "获取健身记录失败: \(error.localizedDescription)"
                        }
                        self?.workoutRecords = []
                        continuation.resume()
                        return
                    }
                    let workouts = (samples as? [HKWorkout]) ?? []
                    self?.workoutRecords = workouts.map { w in
                        WorkoutRecordItem(
                            id: w.uuid,
                            activityType: w.workoutActivityType,
                            activityTypeName: w.workoutActivityType.displayNameZH,
                            startDate: w.startDate,
                            endDate: w.endDate,
                            duration: w.duration,
                            totalEnergyBurned: w.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                            totalDistance: w.totalDistance?.doubleValue(for: .meter()),
                            sourceName: w.sourceRevision.source.name
                        )
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    // 获取最新心率
    private func fetchHeartRateResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return (nil, false)
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            var result: HealthDataItem?
            
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == HKErrorDomain,
                       nsError.code == HKError.errorAuthorizationDenied.rawValue {
                        continuation.resume(returning: (nil, true))
                    } else {
                        print("获取心率数据失败: \(error.localizedDescription)")
                        continuation.resume(returning: (nil, false))
                    }
                    return
                }
                
                // 如果没有数据，返回 nil（这是正常情况，用户可能没有记录心率）
                guard let sample = samples?.first as? HKQuantitySample else {
                    // 没有数据不代表没有权限，这是正常情况
                    continuation.resume(returning: (nil, false))
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = sample.quantity.doubleValue(for: heartRateUnit)
                
                result = HealthDataItem(
                    type: .heartRate,
                    value: value,
                    unit: "bpm",
                    date: sample.endDate,
                    formattedValue: String(format: "%.0f", value)
                )
                
                continuation.resume(returning: (result, false))
            }
            
            healthStore.execute(query)
        }
    }
    
    // 获取今日步数
    private func fetchStepCountResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return (nil, false)
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { query, statistics, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == HKErrorDomain,
                       nsError.code == HKError.errorAuthorizationDenied.rawValue {
                        continuation.resume(returning: (nil, true))
                    } else {
                        print("获取步数数据失败: \(error.localizedDescription)")
                        continuation.resume(returning: (nil, false))
                    }
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: (nil, false))
                    return
                }
                
                let value = sum.doubleValue(for: HKUnit.count())
                
                let item = HealthDataItem(
                    type: .stepCount,
                    value: value,
                    unit: "步",
                    date: now,
                    formattedValue: String(format: "%.0f", value)
                )
                
                continuation.resume(returning: (item, false))
            }
            
            healthStore.execute(query)
        }
    }
}
