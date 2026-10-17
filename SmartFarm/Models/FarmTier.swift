//
//  FarmTier.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import SwiftUI

struct FarmTier: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    var soilMoistureSensors: [Int]
    var relays: [Bool]
    var rgbLight: RGBColor
    var hasTemperatureSensor: Bool = false
    var hasLightSensor: Bool = false
    
    static let firstTier = FarmTier(
        number: 1,
        name: "Перший ярус",
        soilMoistureSensors: [0, 0],
        relays: [false, false],
        rgbLight: RGBColor(red: 1.0, green: 1.0, blue: 1.0),
        hasTemperatureSensor: false,
        hasLightSensor: false
    )
    
    static let secondTier = FarmTier(
        number: 2,
        name: "Другий ярус",
        soilMoistureSensors: [0, 0],
        relays: [false, false],
        rgbLight: RGBColor(red: 1.0, green: 1.0, blue: 1.0),
        hasTemperatureSensor: false,
        hasLightSensor: false
    )
    
    static let thirdTier = FarmTier(
        number: 3,
        name: "Третій ярус (вода)",
        soilMoistureSensors: [],
        relays: [],
        rgbLight: RGBColor(red: 1.0, green: 1.0, blue: 1.0),
        hasTemperatureSensor: false,
        hasLightSensor: false
    )
}
