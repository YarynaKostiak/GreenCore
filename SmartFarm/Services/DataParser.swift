//
//  DataParser.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation

class DataParser {
    
    // Парсинг отриманих даних з Bluetooth
    static func parseSensorData(_ data: Data) -> Result<SensorData, Error> {
        // Спочатку пробуємо як Dictionary
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return parseDictionaryData(dict)
        }
        
        // Якщо не вийшло, пробуємо як прямий JSON Decoder
        do {
            let decoder = JSONDecoder()
            let sensorData = try decoder.decode(SensorData.self, from: data)
            return .success(sensorData)
        } catch {
            print("❌ Помилка парсингу JSON: \(error)")
            return .failure(error)
        }
    }
    
    // Парсинг словникових даних
    private static func parseDictionaryData(_ dict: [String: Any]) -> Result<SensorData, Error> {
        do {
            let temperature = dict["temp"] as? Double ?? dict["temperature"] as? Double ?? 0.0
            let humidity = dict["hum"] as? Double ?? dict["humidity"] as? Double ?? 0.0
            let lightLevel = dict["light"] as? Int ?? dict["photo"] as? Int ?? dict["lightLevel"] as? Int ?? 0
            let waterLevel = dict["water"] as? Int ?? dict["waterLevel"] as? Int ?? 0
            
            // Парсинг датчиків вологості ґрунту
            var soilMoisture1: [Int] = [0, 0]
            var soilMoisture2: [Int] = [0, 0]
            
            if let soilArray = dict["soil"] as? [Int] {
                if soilArray.count >= 4 {
                    soilMoisture1 = Array(soilArray[0..<2])
                    soilMoisture2 = Array(soilArray[2..<4])
                }
            } else {
                if let s1 = dict["soil1"] as? Int { soilMoisture1[0] = s1 }
                if let s2 = dict["soil2"] as? Int { soilMoisture1[1] = s2 }
                if let s3 = dict["soil3"] as? Int { soilMoisture2[0] = s3 }
                if let s4 = dict["soil4"] as? Int { soilMoisture2[1] = s4 }
            }
            
            if let soil1 = dict["soilMoisture1"] as? [Int], soil1.count >= 2 {
                soilMoisture1 = Array(soil1[0..<2])
            }
            
            if let soil2 = dict["soilMoisture2"] as? [Int], soil2.count >= 2 {
                soilMoisture2 = Array(soil2[0..<2])
            }
            
            // Парсинг реле
            var relays: [Bool] = [false, false, false, false]
            
            if let relayArray = dict["relays"] as? [Bool] {
                for i in 0..<min(relayArray.count, 4) {
                    relays[i] = relayArray[i]
                }
            } else if let relayArray = dict["relays"] as? [Int] {
                for i in 0..<min(relayArray.count, 4) {
                    relays[i] = relayArray[i] == 1
                }
            }
            
            // ========== ПАРСИНГ ДВОХ RGB ДЖЕРЕЛ ==========
            
            // Значення за замовчуванням (білий колір)
            var rgbLight = RGBColor(red: 1.0, green: 1.0, blue: 1.0)
            var stripLight = RGBColor(red: 1.0, green: 1.0, blue: 1.0)
            
            // Варіант 1: Парсинг з вкладених об'єктів rgbLights та stripLights
            if let rgbDict = dict["rgbLights"] as? [String: Any] {
                let r = (rgbDict["r"] as? Double ?? 255) / 255.0
                let g = (rgbDict["g"] as? Double ?? 255) / 255.0
                let b = (rgbDict["b"] as? Double ?? 255) / 255.0
                
                // Якщо enabled = false, то колір чорний (0,0,0)
                if let enabled = rgbDict["enabled"] as? Bool, !enabled {
                    rgbLight = RGBColor(red: 0, green: 0, blue: 0)
                } else {
                    rgbLight = RGBColor(red: r, green: g, blue: b)
                }
                print("📱 RGB Лампа: R=\(Int(r*255)), G=\(Int(g*255)), B=\(Int(b*255))")
            }
            
            if let stripDict = dict["stripLights"] as? [String: Any] {
                let r = (stripDict["r"] as? Double ?? 255) / 255.0
                let g = (stripDict["g"] as? Double ?? 255) / 255.0
                let b = (stripDict["b"] as? Double ?? 255) / 255.0
                
                // Якщо enabled = false, то колір чорний (0,0,0)
                if let enabled = stripDict["enabled"] as? Bool, !enabled {
                    stripLight = RGBColor(red: 0, green: 0, blue: 0)
                } else {
                    stripLight = RGBColor(red: r, green: g, blue: b)
                }
                print("📱 RGB Стрічка: R=\(Int(r*255)), G=\(Int(g*255)), B=\(Int(b*255))")
            }
            
            // Варіант 2: Парсинг з простих полів (для сумісності)
            if let r = dict["r"] as? Double,
               let g = dict["g"] as? Double,
               let b = dict["b"] as? Double {
                rgbLight = RGBColor(
                    red: r / 255.0,
                    green: g / 255.0,
                    blue: b / 255.0
                )
            }
            
            if let stripR = dict["stripR"] as? Double,
               let stripG = dict["stripG"] as? Double,
               let stripB = dict["stripB"] as? Double {
                stripLight = RGBColor(
                    red: stripR / 255.0,
                    green: stripG / 255.0,
                    blue: stripB / 255.0
                )
            }
            
            // Варіант 3: Визначаємо по масиву rgbLights
            if let rgbArray = dict["rgbLights"] as? [[String: Any]] {
                if rgbArray.count >= 1 {
                    let first = rgbArray[0]
                    let r1 = (first["r"] as? Double ?? 255) / 255.0
                    let g1 = (first["g"] as? Double ?? 255) / 255.0
                    let b1 = (first["b"] as? Double ?? 255) / 255.0
                    rgbLight = RGBColor(red: r1, green: g1, blue: b1)
                }
                
                if rgbArray.count >= 2 {
                    let second = rgbArray[1]
                    let r2 = (second["r"] as? Double ?? 255) / 255.0
                    let g2 = (second["g"] as? Double ?? 255) / 255.0
                    let b2 = (second["b"] as? Double ?? 255) / 255.0
                    stripLight = RGBColor(red: r2, green: g2, blue: b2)
                }
            }
            
            // Якщо є інформація про стан увімкнення
            if let rgbEnabled = dict["rgbEnabled"] as? Bool, !rgbEnabled {
                rgbLight = RGBColor(red: 0, green: 0, blue: 0)
                print("📱 RGB Лампа: вимкнено")
            }
            
            if let stripEnabled = dict["stripEnabled"] as? Bool, !stripEnabled {
                stripLight = RGBColor(red: 0, green: 0, blue: 0)
                print("📱 RGB Стрічка: вимкнено")
            }
            
            let sensorData = SensorData(
                temperature: temperature,
                humidity: humidity,
                lightLevel: lightLevel,
                waterLevel: waterLevel,
                soilMoisture1: soilMoisture1,
                soilMoisture2: soilMoisture2,
                relays: relays,
                rgbLight: rgbLight,
                stripLight: stripLight
            )
            
            return .success(sensorData)
        } catch {
            return .failure(error)
        }
    }
    
    // Форматування даних для відправки команд на реле
    static func createRelayCommand(relayIndex: Int, state: Bool) -> Data? {
        let command: [String: Any] = [
            "type": "relay",
            "index": relayIndex,
            "state": state,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return try? JSONSerialization.data(withJSONObject: command)
    }
    
    // Форматування даних для відправки команд на RGB лампу (перший ярус)
    static func createRGBLightCommand(red: Double, green: Double, blue: Double, enabled: Bool) -> Data? {
        let command: [String: Any] = [
            "type": "rgb",
            "enabled": enabled,
            "r": Int(red),
            "g": Int(green),
            "b": Int(blue),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return try? JSONSerialization.data(withJSONObject: command)
    }
    
    // Форматування даних для відправки команд на RGB стрічку (другий ярус)
    static func createStripLightCommand(red: Double, green: Double, blue: Double, enabled: Bool) -> Data? {
        let command: [String: Any] = [
            "type": "strip",
            "enabled": enabled,
            "r": Int(red),
            "g": Int(green),
            "b": Int(blue),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return try? JSONSerialization.data(withJSONObject: command)
    }
    
    // Валідація даних
    static func validateSensorData(_ data: SensorData) -> Bool {
        guard data.temperature >= -40 && data.temperature <= 100 else {
            print("❌ Температура поза діапазоном: \(data.temperature)")
            return false
        }
        guard data.humidity >= 0 && data.humidity <= 100 else {
            print("❌ Вологість поза діапазоном: \(data.humidity)")
            return false
        }
        guard data.lightLevel >= 0 && data.lightLevel <= 100 else {
            print("❌ Освітленість поза діапазоном: \(data.lightLevel)")
            return false
        }
        guard data.waterLevel >= 0 && data.waterLevel <= 100 else {
            print("❌ Рівень води поза діапазоном: \(data.waterLevel)")
            return false
        }
        
        for (index, value) in data.soilMoisture1.enumerated() {
            guard value >= 0 && value <= 100 else {
                print("❌ Ґрунт 1-\(index) поза діапазоном: \(value)")
                return false
            }
        }
        
        for (index, value) in data.soilMoisture2.enumerated() {
            guard value >= 0 && value <= 100 else {
                print("❌ Ґрунт 2-\(index) поза діапазоном: \(value)")
                return false
            }
        }
        
        // Валідація RGB лампи
        guard data.rgbLight.red >= 0 && data.rgbLight.red <= 1.0 else {
            print("❌ RGB лампа червоний поза діапазоном: \(data.rgbLight.red)")
            return false
        }
        guard data.rgbLight.green >= 0 && data.rgbLight.green <= 1.0 else {
            print("❌ RGB лампа зелений поза діапазоном: \(data.rgbLight.green)")
            return false
        }
        guard data.rgbLight.blue >= 0 && data.rgbLight.blue <= 1.0 else {
            print("❌ RGB лампа синій поза діапазоном: \(data.rgbLight.blue)")
            return false
        }
        
        // Валідація RGB стрічки
        guard data.stripLight.red >= 0 && data.stripLight.red <= 1.0 else {
            print("❌ RGB стрічка червоний поза діапазоном: \(data.stripLight.red)")
            return false
        }
        guard data.stripLight.green >= 0 && data.stripLight.green <= 1.0 else {
            print("❌ RGB стрічка зелений поза діапазоном: \(data.stripLight.green)")
            return false
        }
        guard data.stripLight.blue >= 0 && data.stripLight.blue <= 1.0 else {
            print("❌ RGB стрічка синій поза діапазоном: \(data.stripLight.blue)")
            return false
        }
        
        return true
    }
    
    // Допоміжна функція для логування отриманих даних
    static func logReceivedData(_ data: SensorData) {
        print("📊 ====== ОТРИМАНІ ДАНІ ======")
        print("🌡️ Температура: \(data.temperature)°C")
        print("💧 Вологість: \(data.humidity)%")
        print("☀️ Освітленість: \(data.lightLevel)%")
        print("💦 Рівень води: \(data.waterLevel)%")
        print("🌱 Ґрунт 1: \(data.soilMoisture1)")
        print("🌱 Ґрунт 2: \(data.soilMoisture2)")
        print("🔌 Реле: \(data.relays)")
        
        print("💡 RGB Лампа: R=\(Int(data.rgbLight.red*255)), G=\(Int(data.rgbLight.green*255)), B=\(Int(data.rgbLight.blue*255))")
        print("💡 RGB Стрічка: R=\(Int(data.stripLight.red*255)), G=\(Int(data.stripLight.green*255)), B=\(Int(data.stripLight.blue*255))")
        
        print("==============================")
    }
}
