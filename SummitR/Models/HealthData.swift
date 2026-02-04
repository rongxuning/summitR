//
//  HealthData.swift
//  SummitR
//
//  Created on 2026-01-23.
//

import Foundation
import HealthKit

struct HealthDataItem: Identifiable {
    let id = UUID()
    let type: HealthDataType
    let value: Double
    let unit: String
    let date: Date
    let formattedValue: String
    
    enum HealthDataType: CaseIterable {
        case heartRate
        case restingHeartRate
        case stepCount
        case distanceWalkingRunning
        case flightsClimbed
        case activeEnergyBurned
        case basalEnergyBurned
        case dietaryEnergyConsumed
        
        var displayName: String {
            switch self {
            case .heartRate: return "心率"
            case .restingHeartRate: return "静息心率"
            case .stepCount: return "步数"
            case .distanceWalkingRunning: return "步行+跑步"
            case .flightsClimbed: return "爬楼层数"
            case .activeEnergyBurned: return "活动能量"
            case .basalEnergyBurned: return "静息能量"
            case .dietaryEnergyConsumed: return "饮食能量"
            }
        }
        
        var icon: String {
            switch self {
            case .heartRate, .restingHeartRate: return "heart.fill"
            case .stepCount: return "figure.walk"
            case .distanceWalkingRunning: return "figure.run"
            case .flightsClimbed: return "figure.stairs"
            case .activeEnergyBurned: return "flame.fill"
            case .basalEnergyBurned: return "bed.double.fill"
            case .dietaryEnergyConsumed: return "fork.knife"
            }
        }
        
        var color: String {
            switch self {
            case .heartRate, .restingHeartRate: return "red"
            case .stepCount, .distanceWalkingRunning: return "blue"
            case .flightsClimbed: return "green"
            case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed: return "orange"
            }
        }
    }
}
