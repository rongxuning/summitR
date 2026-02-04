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
import CoreLocation

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
    
    // 需要请求的权限（参考健康 App 常见数据类型）
    private var healthReadTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        if let t = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(t) }
        return types
    }
    
    private var readTypes: Set<HKObjectType> { healthReadTypes }
    
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
    
    // 获取健康数据（参考健康 App，多类数据平铺）
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
        
        if let item = await fetchRestingHeartRateResult().item { items.append(item) }
        if let item = await fetchDistanceWalkingRunningResult().item { items.append(item) }
        if let item = await fetchFlightsClimbedResult().item { items.append(item) }
        if let item = await fetchActiveEnergyBurnedResult().item { items.append(item) }
        if let item = await fetchBasalEnergyBurnedResult().item { items.append(item) }
        if let item = await fetchDietaryEnergyConsumedResult().item { items.append(item) }
        
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
    
    // MARK: - 健身详情（单条锻炼的心率、路线）
    
    /// 根据 UUID 获取单条 HKWorkout（用于详情页拉取路线等）
    func fetchWorkout(byUUID uuid: UUID) async -> HKWorkout? {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForObject(with: uuid)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout])?.first)
            }
            healthStore.execute(query)
        }
    }
    
    /// 获取某时间段内的心率样本（用于详情页心率曲线），返回 (时间, bpm)
    func fetchHeartRateSamples(from start: Date, to end: Date) async -> [(Date, Double)] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        return await withCheckedContinuation { continuation in
            var result: [(Date, Double)] = []
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let samples = samples as? [HKQuantitySample], error == nil {
                    let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    result = samples.map { ($0.endDate, $0.quantity.doubleValue(for: unit)) }
                }
                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }
    
    /// 获取某次锻炼的路线坐标（用于详情页地图），需先有该次锻炼的 HKWorkout
    func fetchWorkoutRouteLocations(workout: HKWorkout) async -> [CLLocation] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        guard let routeSamples = await withCheckedContinuation({ (cont: CheckedContinuation<[HKSample]?, Never>) in
            let q = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                cont.resume(returning: samples)
            }
            healthStore.execute(q)
        }), let route = routeSamples.first as? HKWorkoutRoute else {
            return []
        }
        var allLocations: [CLLocation] = []
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let routeQuery = HKWorkoutRouteQuery(route: route) { _, locationsOrNil, done, error in
                if let locs = locationsOrNil { allLocations.append(contentsOf: locs) }
                if done || error != nil { cont.resume() }
            }
            healthStore.execute(routeQuery)
        }
        return allLocations
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
    
    // MARK: - 扩展健康数据（今日汇总或最新一条）
    
    private func fetchRestingHeartRateResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return (nil, false) }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let e = error as NSError?, e.domain == HKErrorDomain, e.code == HKError.errorAuthorizationDenied.rawValue {
                    cont.resume(returning: (nil, true)); return
                }
                guard let s = samples?.first as? HKQuantitySample else { cont.resume(returning: (nil, false)); return }
                let v = s.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                let item = HealthDataItem(type: .restingHeartRate, value: v, unit: "bpm", date: s.endDate, formattedValue: String(format: "%.0f", v))
                cont.resume(returning: (item, false))
            }
            healthStore.execute(q)
        }
    }
    
    private func fetchTodayStatistics(identifier: HKQuantityTypeIdentifier, unit: HKUnit, type: HealthDataItem.HealthDataType, displayUnit: String, format: String) async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        guard let qtyType = HKQuantityType.quantityType(forIdentifier: identifier) else { return (nil, false) }
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: qtyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let e = error as NSError?, e.domain == HKErrorDomain, e.code == HKError.errorAuthorizationDenied.rawValue {
                    cont.resume(returning: (nil, true)); return
                }
                guard let sum = stats?.sumQuantity() else { cont.resume(returning: (nil, false)); return }
                let v = sum.doubleValue(for: unit)
                let item = HealthDataItem(type: type, value: v, unit: displayUnit, date: now, formattedValue: String(format: format, v))
                cont.resume(returning: (item, false))
            }
            healthStore.execute(q)
        }
    }
    
    private func fetchDistanceWalkingRunningResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        let r = await fetchTodayStatistics(identifier: .distanceWalkingRunning, unit: .meter(), type: .distanceWalkingRunning, displayUnit: "米", format: "%.0f")
        guard let item = r.item else { return (nil, r.authorizationDenied) }
        let km = item.value / 1000
        return (HealthDataItem(type: .distanceWalkingRunning, value: item.value, unit: "公里", date: item.date, formattedValue: String(format: "%.2f", km)), false)
    }
    
    private func fetchFlightsClimbedResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        await fetchTodayStatistics(identifier: .flightsClimbed, unit: HKUnit.count(), type: .flightsClimbed, displayUnit: "层", format: "%.0f")
    }
    
    private func fetchActiveEnergyBurnedResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        await fetchTodayStatistics(identifier: .activeEnergyBurned, unit: .kilocalorie(), type: .activeEnergyBurned, displayUnit: "千卡", format: "%.0f")
    }
    
    private func fetchBasalEnergyBurnedResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        await fetchTodayStatistics(identifier: .basalEnergyBurned, unit: .kilocalorie(), type: .basalEnergyBurned, displayUnit: "千卡", format: "%.0f")
    }
    
    private func fetchDietaryEnergyConsumedResult() async -> (item: HealthDataItem?, authorizationDenied: Bool) {
        await fetchTodayStatistics(identifier: .dietaryEnergyConsumed, unit: .kilocalorie(), type: .dietaryEnergyConsumed, displayUnit: "千卡", format: "%.0f")
    }
}
