//
//  SensorData.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import SwiftUI

// MARK: - Основна модель даних сенсорів
struct SensorData: Codable {
    let temperature: Double
    let humidity: Double
    let lightLevel: Int
    let waterLevel: Int
    let soilMoisture1: [Int]
    let soilMoisture2: [Int]
    let relays: [Bool]
    let rgbLight: RGBColor
    let stripLight: RGBColor

    // Обчислювані властивості для зручності
    var averageSoilMoisture1: Int {
        return soilMoisture1.reduce(0, +) / soilMoisture1.count
    }
    
    var averageSoilMoisture2: Int {
        return soilMoisture2.reduce(0, +) / soilMoisture2.count
    }
    
    var isWaterLow: Bool {
        return waterLevel < 30
    }
    
    var isWaterCritical: Bool {
        return waterLevel < 15
    }
    
    var temperatureString: String {
        return String(format: "%.1f°C", temperature)
    }
    
    var humidityString: String {
        return String(format: "%.0f%%", humidity)
    }
    
    var lightLevelString: String {
        return "\(lightLevel)%"
    }
    
    var waterLevelString: String {
        return "\(waterLevel)%"
    }
}

