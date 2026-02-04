//
//  WorkoutRecord.swift
//  SummitR
//

import Foundation
import HealthKit

/// 单条健身记录（由 HKWorkout 转换，用于卡片展示）
struct WorkoutRecordItem: Identifiable {
    let id: UUID
    let activityType: HKWorkoutActivityType
    let activityTypeName: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalEnergyBurned: Double?  // 千卡
    let totalDistance: Double?      // 米
    let sourceName: String?
    
    var durationFormatted: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        if m >= 60 {
            let h = m / 60
            let min = m % 60
            return String(format: "%d 小时 %02d 分", h, min)
        }
        return String(format: "%d 分 %02d 秒", m, s)
    }
    
    var distanceFormatted: String? {
        guard let d = totalDistance, d > 0 else { return nil }
        if d >= 1000 {
            return String(format: "%.2f 公里", d / 1000)
        }
        return String(format: "%.0f 米", d)
    }
    
    var energyFormatted: String? {
        guard let e = totalEnergyBurned, e > 0 else { return nil }
        return String(format: "%.0f 千卡", e)
    }
    
    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: startDate)
    }
    
    var timeRangeFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "zh_CN")
        return "\(f.string(from: startDate)) – \(f.string(from: endDate))"
    }
}

// MARK: - HKWorkoutActivityType 中文显示名
extension HKWorkoutActivityType {
    var displayNameZH: String {
        switch self {
        case .running: return "跑步"
        case .cycling: return "骑行"
        case .walking: return "步行"
        case .swimming: return "游泳"
        case .yoga: return "瑜伽"
        case .functionalStrengthTraining: return "力量训练"
        case .traditionalStrengthTraining: return "传统力量训练"
        case .highIntensityIntervalTraining: return "高强度间歇"
        case .coreTraining: return "核心训练"
        case .elliptical: return "椭圆机"
        case .rowing: return "划船"
        case .stairClimbing: return "爬楼梯"
        case .hiking: return "徒步"
        case .dance: return "舞蹈"
        case .barre: return "芭蕾把杆"
        case .pilates: return "普拉提"
        case .crossTraining: return "交叉训练"
        case .mixedCardio: return "混合有氧"
        case .kickboxing: return "拳击"
        case .boxing: return "拳击"
        case .golf: return "高尔夫"
        case .tennis: return "网球"
        case .basketball: return "篮球"
        case .soccer: return "足球"
        case .hockey: return "冰球"
        case .downhillSkiing: return "滑雪"
        case .snowboarding: return "单板滑雪"
        case .skatingSports: return "滑冰"
        case .surfingSports: return "冲浪"
        case .waterSports: return "水上运动"
        case .fishing: return "钓鱼"
        case .hunting: return "狩猎"
        case .play: return "玩耍"
        case .mindAndBody: return "身心"
        case .flexibility: return "柔韧"
        case .cooldown: return "放松"
        case .wheelchairWalkPace: return "轮椅步行"
        case .wheelchairRunPace: return "轮椅跑步"
        case .preparationAndRecovery: return "准备与恢复"
        case .other: return "其他"
        @unknown default: return "其他"
        }
    }
}
