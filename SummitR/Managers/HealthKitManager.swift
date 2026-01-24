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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 需要请求的权限
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    ]
    
    init() {
        checkAuthorizationStatus()
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
        
        isAuthorized = heartRateStatus == .sharingAuthorized && stepCountStatus == .sharingAuthorized
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
            await checkAuthorizationStatus()
            
            if isAuthorized {
                await fetchHealthData()
            } else {
                errorMessage = "授权被拒绝，请在设置中允许访问健康数据"
            }
        } catch {
            errorMessage = "授权请求失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // 获取健康数据
    func fetchHealthData() async {
        guard isAuthorized else {
            await requestAuthorization()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        var items: [HealthDataItem] = []
        
        // 获取心率数据
        if let heartRate = await fetchHeartRate() {
            items.append(heartRate)
        }
        
        // 获取步数数据
        if let stepCount = await fetchStepCount() {
            items.append(stepCount)
        }
        
        healthDataItems = items.sorted { $0.date > $1.date }
        isLoading = false
    }
    
    // 获取最新心率
    private func fetchHeartRate() async -> HealthDataItem? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
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
                    print("获取心率数据失败: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
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
                
                continuation.resume(returning: result)
            }
            
            healthStore.execute(query)
        }
    }
    
    // 获取今日步数
    private func fetchStepCount() async -> HealthDataItem? {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
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
                    print("获取步数数据失败: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
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
                
                continuation.resume(returning: item)
            }
            
            healthStore.execute(query)
        }
    }
}
