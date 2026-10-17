//
//  WaterLevelStatus.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import SwiftUI

enum WaterLevelStatus {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .red
        case .medium: return .yellow
        case .high: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "checkmark.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .low: return "Мало води"
        case .medium: return "Середній рівень"
        case .high: return "Достатньо"
        }
    }
    
    init(level: Int) {
        switch level {
        case 0..<30: self = .low
        case 30..<70: self = .medium
        default: self = .high
        }
    }
}
