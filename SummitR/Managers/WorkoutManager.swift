//
//  WorkoutManager.swift
//  SummitR
//

import Foundation
import HealthKit
import Combine
import SwiftUI

/// 管理锻炼会话与实时数据（HKWorkoutSession + HKLiveWorkoutBuilder）
@MainActor
class WorkoutManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isWorkoutActive = false
    @Published var activityType: HKWorkoutActivityType = .running
    @Published var activityTypeName: String = "跑步"
    @Published var startDate: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double?
    @Published var averageHeartRate: Double?
    @Published var activeEnergyBurned: Double = 0  // 动态消耗 kcal
    @Published var totalEnergyBurned: Double = 0   // 总消耗（动态+静息）
    @Published var distance: Double = 0            // 米
    @Published var flightsClimbed: Double = 0      // 爬楼层数
    @Published var errorMessage: String?
    /// 锻炼期间心率样本（时间, bpm），用于实时曲线与各区时长
    @Published var heartRateSamples: [(Date, Double)] = []
    
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var elapsedTimer: Timer?
    private var liveHeartRateQuery: HKAnchoredObjectQuery?
    private var restingHeartRate: Double = 60
    private var userAge: Int = 34
    private var maxHeartRate: Double { 206.9 - 0.67 * Double(userAge) }
    private var heartRateReserve: Double { max(0, maxHeartRate - restingHeartRate) }
    
    /// 当前心率所在区间索引 (0-5)
    var currentZoneIndex: Int? {
        guard let hr = heartRate, heartRateReserve > 0 else { return nil }
        let pct = (hr - restingHeartRate) / heartRateReserve
        if pct < 0.60 { return 0 }
        if pct < 0.70 { return 1 }
        if pct < 0.80 { return 2 }
        if pct < 0.90 { return 3 }
        if pct < 0.95 { return 4 }
        return 5
    }
    
    override init() {
        super.init()
    }
    
    /// 请求锻炼所需权限并加载静息心率、年龄
    func prepareForWorkout() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "此设备不支持 HealthKit"
            return
        }
        errorMessage = nil
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        var typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
        ]
        if let t = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) { typesToRead.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { typesToRead.insert(t) }
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            restingHeartRate = await fetchRestingHeartRate()
            userAge = await fetchUserAge()
        } catch {
            errorMessage = "授权失败: \(error.localizedDescription)"
        }
    }
    
    private func fetchRestingHeartRate() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 60 }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let s = samples?.first as? HKQuantitySample else { cont.resume(returning: 60); return }
                cont.resume(returning: s.quantity.doubleValue(for: .count().unitDivided(by: .minute())))
            }
            healthStore.execute(q)
        }
    }
    
    private func fetchUserAge() async -> Int {
        guard let type = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) else { return 34 }
        return await withCheckedContinuation { cont in
            do {
                let dob = try healthStore.dateOfBirthComponents()
                let age = Calendar.current.dateComponents([.year], from: dob.date!, to: Date()).year ?? 34
                cont.resume(returning: age)
            } catch {
                cont.resume(returning: 34)
            }
        }
    }
    
    /// 开始锻炼
    func startWorkout(activityType: HKWorkoutActivityType) async {
        guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }
        self.activityType = activityType
        self.activityTypeName = activityType.displayNameZH
        errorMessage = nil
        
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            builder?.dataSource = dataSource
            if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                dataSource.enableCollection(for: hrType, predicate: nil)
            }
            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                dataSource.enableCollection(for: energyType, predicate: nil)
            }
            if let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
                dataSource.enableCollection(for: distType, predicate: nil)
            }
            if let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
                dataSource.enableCollection(for: flightsType, predicate: nil)
            }
            session?.delegate = self
            builder?.delegate = self
            
            let start = Date()
            startDate = start
            try await session?.startActivity(with: start)
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                builder?.beginCollection(withStart: start) { _, err in
                    if let e = err { cont.resume(throwing: e); return }
                    cont.resume()
                }
            }
            
            isWorkoutActive = true
            resetStats()
            startElapsedTimer()
            startLiveHeartRateQuery(from: start)
        } catch {
            errorMessage = "启动锻炼失败: \(error.localizedDescription)"
        }
    }
    
    /// 结束锻炼（用户点击停止时调用）
    func endWorkout() {
        guard let session = session else { return }
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        stopLiveHeartRateQuery()
        session.end()
    }
    
    private func finishWorkoutSession() async {
        guard let b = builder else {
            session = nil
            builder = nil
            isWorkoutActive = false
            return
        }
        let end = Date()
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                b.endCollection(withEnd: end) { _, err in
                    if let e = err { cont.resume(throwing: e); return }
                    cont.resume()
                }
            }
            _ = await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                b.finishWorkout { _, _ in cont.resume() }
            }
        } catch {
            errorMessage = "保存锻炼失败: \(error.localizedDescription)"
        }
        stopLiveHeartRateQuery()
        session = nil
        builder = nil
        isWorkoutActive = false
    }
    
    private func resetStats() {
        elapsedTime = 0
        heartRate = nil
        averageHeartRate = nil
        activeEnergyBurned = 0
        totalEnergyBurned = 0
        distance = 0
        flightsClimbed = 0
        heartRateSamples = []
    }
    
    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let start = self?.startDate else { return }
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
        }
        RunLoop.current.add(elapsedTimer!, forMode: .common)
    }
    
    /// 从 HealthKit 实时查询心率（Watch/蓝牙写入的数据），作为 builder 的补充
    private func startLiveHeartRateQuery(from startDate: Date) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.updateHeartRateFromSamples(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.updateHeartRateFromSamples(samples)
        }
        healthStore.execute(query)
        liveHeartRateQuery = query
    }
    
    private nonisolated func updateHeartRateFromSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let latest = samples.max(by: { $0.endDate < $1.endDate })
        guard let sample = latest else { return }
        let value = sample.quantity.doubleValue(for: unit)
        Task { @MainActor in
            heartRate = value
            let sum = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
            averageHeartRate = sum / Double(samples.count)
            let lastDate = heartRateSamples.last?.0 ?? .distantPast
            for s in samples where s.endDate > lastDate {
                heartRateSamples.append((s.endDate, s.quantity.doubleValue(for: unit)))
            }
        }
    }
    
    private func stopLiveHeartRateQuery() {
        if let q = liveHeartRateQuery {
            healthStore.stop(q)
            liveHeartRateQuery = nil
        }
    }
    
    func zoneBounds(zoneIndex: Int) -> (low: Int, high: Int)? {
        guard zoneIndex >= 0, zoneIndex < 6 else { return nil }
        let pcts: [(Double, Double)] = [(0.50, 0.60), (0.60, 0.70), (0.70, 0.80), (0.80, 0.90), (0.90, 0.95), (0.95, 1.00)]
        let (lo, hi) = pcts[zoneIndex]
        let low = Int(restingHeartRate + heartRateReserve * lo)
        let high = Int(restingHeartRate + heartRateReserve * hi)
        return (low, high)
    }
    
    /// 供实时页图表使用
    var workoutRestingHR: Double { restingHeartRate }
    var workoutReserve: Double { heartRateReserve }
    var workoutMaxHR: Double { maxHeartRate }
    
    /// 六区各自占用时间（秒），由 heartRateSamples 计算
    var timeInZones: [TimeInterval]? {
        timeInZonesFromSamples(heartRateSamples)
    }
    
    private func timeInZonesFromSamples(_ samples: [(Date, Double)]) -> [TimeInterval]? {
        guard !samples.isEmpty, heartRateReserve > 0, let start = startDate else { return nil }
        let end = Date()
        let resting = restingHeartRate
        let reserve = heartRateReserve
        var zones: [TimeInterval] = Array(repeating: 0, count: 6)
        
        func zoneIndex(hr: Double) -> Int {
            let pct = (hr - resting) / reserve
            if pct < 0.60 { return 0 }
            if pct < 0.70 { return 1 }
            if pct < 0.80 { return 2 }
            if pct < 0.90 { return 3 }
            if pct < 0.95 { return 4 }
            return 5
        }
        
        let sorted = samples.sorted { $0.0 < $1.0 }
        let firstDate = sorted[0].0
        zones[zoneIndex(hr: sorted[0].1)] += firstDate.timeIntervalSince(start)
        for i in 0..<(sorted.count - 1) {
            let dt = sorted[i + 1].0.timeIntervalSince(sorted[i].0)
            zones[zoneIndex(hr: sorted[i].1)] += dt
        }
        zones[zoneIndex(hr: sorted.last!.1)] += end.timeIntervalSince(sorted.last!.0)
        return zones
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            if toState == .ended {
                await finishWorkoutSession()
            }
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "锻炼异常: \(error.localizedDescription)"
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let qtyType = type as? HKQuantityType else { continue }
                guard let stats = workoutBuilder.statistics(for: qtyType) else { continue }
                switch qtyType.identifier {
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    if let v = stats.mostRecentQuantity()?.doubleValue(for: unit) {
                        heartRate = v
                        heartRateSamples.append((Date(), v))
                    }
                    averageHeartRate = stats.averageQuantity()?.doubleValue(for: unit)
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    activeEnergyBurned = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    distance = stats.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
                    flightsClimbed = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                default:
                    break
                }
            }
            totalEnergyBurned = activeEnergyBurned
        }
    }
}
