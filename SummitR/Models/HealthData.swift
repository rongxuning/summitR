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
    
    enum HealthDataType {
        case heartRate
        case stepCount
        
        var displayName: String {
            switch self {
            case .heartRate:
                return "心率"
            case .stepCount:
                return "步数"
            }
        }
        
        var icon: String {
            switch self {
            case .heartRate:
                return "heart.fill"
            case .stepCount:
                return "figure.walk"
            }
        }
        
        var color: String {
            switch self {
            case .heartRate:
                return "red"
            case .stepCount:
                return "blue"
            }
        }
    }
}
