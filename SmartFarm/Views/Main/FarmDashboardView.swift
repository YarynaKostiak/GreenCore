//
//  FarmDashboardView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation
import CoreBluetooth

struct FarmDashboardView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var showingAlert = false
    @State private var waterAlertShown = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let data = bluetoothManager.sensorData {
                        // Секція 1: Загальні датчики
                        GeneralSensorsSection(
                            temperature: data.temperature,
                            humidity: data.humidity,
                            lightLevel: data.lightLevel
                        )
                        
                        TierSection(
                            title: "Перший ярус",
                            tierNumber: 1,
                            soilMoisture: safeSoilMoisture(data.soilMoisture1),
                            relayStates: safeRelayStates(for: 1, from: data.relays),
                            rgbLight: data.rgbLight,      // RGB лампа для першого ярусу
                            stripLight: RGBColor(red: 0, green: 0, blue: 0), // Не використовується
                            bluetoothManager: bluetoothManager
                        )
                                               
                                               // Секція 3: Другий ярус - RGB стрічка
                        TierSection(
                            title: "Другий ярус",
                            tierNumber: 2,
                            soilMoisture: safeSoilMoisture(data.soilMoisture2),
                            relayStates: safeRelayStates(for: 2, from: data.relays),
                            rgbLight: RGBColor(red: 0, green: 0, blue: 0), // Не використовується
                            stripLight: data.stripLight,  // RGB стрічка для другого ярусу
                            bluetoothManager: bluetoothManager
                        )
                        
                        // Секція 4: Керування водою
                        WaterSection(
                            waterLevel: data.waterLevel,
                            onLowWater: {
                                if !waterAlertShown {
                                    waterAlertShown = true
                                    showingAlert = true
                                }
                            }
                        )
                    } else {
                        // Показуємо індикатор завантаження
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(2)
                            Text("Очікування даних...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Переконайтеся, що Smart Farm увімкнено")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
                .padding()
            }
            .navigationTitle("Розумна ферма")
            .navigationBarTitleDisplayMode(.large)
            .alert("Увага!", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Рівень води низький! Будь ласка, долийте воду.")
            }
        }
    }
    
    // Безпечне отримання вологості ґрунту
    private func safeSoilMoisture(_ moisture: [Int]) -> [Int] {
        if moisture.count >= 2 {
            return moisture
        } else {
            return [0, 0] // Значення за замовчуванням
        }
    }
    
    // Безпечне отримання реле для конкретного ярусу
    private func safeRelayStates(for tier: Int, from relays: [Bool]) -> [Bool] {
        switch tier {
        case 1:
            // Перший ярус: реле 0 та 1
            return [
                relays.count > 0 ? relays[0] : false,
                relays.count > 1 ? relays[1] : false
            ]
        case 2:
            // Другий ярус: реле 2 та 3
            return [
                relays.count > 2 ? relays[2] : false,
                relays.count > 3 ? relays[3] : false
            ]
        default:
            return [false, false]
        }
    }
    
    // Безпечне отримання RGB світла
    private func safeRGBLight(for index: Int, from rgbLights: [RGBColor]) -> RGBColor {
        if rgbLights.count > index {
            return rgbLights[index]
        } else {
            return RGBColor(red: 1.0, green: 1.0, blue: 1.0) // Білий колір за замовчуванням
        }
    }
}


#Preview {
    FarmDashboardView(bluetoothManager: BluetoothManager())
}
