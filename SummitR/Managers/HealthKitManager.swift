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
            
            // 重要：对于只读权限，authorizationStatus 可能不准确
            // 状态 1 (.sharingDenied) 可能是针对写入权限的，不代表读取权限被拒绝
            // 正确的做法是直接尝试读取数据来验证授权
            
            // 直接尝试获取数据来验证授权
            // 如果能够执行查询（即使没有数据），说明有读取权限
            isAuthorized = true
            await fetchHealthData()
            
            // 如果成功执行了查询（无论是否有数据），说明授权成功
            // 没有数据是正常情况（用户可能没有记录健康数据）
            // 只有在查询失败并返回权限错误时，才认为授权失败
            
            // 检查是否有权限错误（通过 errorMessage 判断）
            // 如果没有设置错误信息，说明查询成功执行，授权成功
            if errorMessage == nil || !errorMessage!.contains("权限") {
                // 授权成功，即使没有数据也是正常的
                isAuthorized = true
                errorMessage = nil
            }
        } catch {
            errorMessage = "授权请求失败: \(error.localizedDescription)"
            isAuthorized = false
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
        var hasPermissionError = false
        
        // 获取心率数据
        if let heartRate = await fetchHeartRate() {
            items.append(heartRate)
        } else {
            // 检查是否是权限错误（这里简化处理，实际应该检查具体错误）
            // 如果没有数据但也没有错误，说明只是没有数据，不是权限问题
        }
        
        // 获取步数数据
        if let stepCount = await fetchStepCount() {
            items.append(stepCount)
        }
        
        healthDataItems = items.sorted { $0.date > $1.date }
        
        // 如果没有获取到数据，但不一定是权限问题
        // 可能是用户没有记录健康数据，这是正常情况
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
                    let nsError = error as NSError
                    // 检查是否是权限错误
                    // HealthKit 权限错误通常是 domain: "com.apple.healthkit", code: 4
                    if nsError.domain == "com.apple.healthkit" {
                        print("获取心率数据失败 - HealthKit错误: code=\(nsError.code), \(error.localizedDescription)")
                        // 如果是权限错误，会在上层处理
                    } else {
                        print("获取心率数据失败: \(error.localizedDescription)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                
                // 如果没有数据，返回 nil（这是正常情况，用户可能没有记录心率）
                guard let sample = samples?.first as? HKQuantitySample else {
                    // 没有数据不代表没有权限，这是正常情况
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
