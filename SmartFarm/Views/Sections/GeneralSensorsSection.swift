//
//  GeneralSensorsSection.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct GeneralSensorsSection: View {
    let temperature: Double
    let humidity: Double
    let lightLevel: Int
    
    @State private var showingDetails = false
    @State private var selectedSensor: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Загальні показники",
                icon: "thermometer.medium",
                color: .orange,
                showBadge: true,
                badgeValue: "Оновлено щойно"
            ) {
                withAnimation {
                    showingDetails.toggle()
                }
            }
            
            // Основні датчики
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SensorCard(
                    title: "Температура",
                    value: String(format: "%.1f°C", temperature),
                    icon: "thermometer",
                    color: .orange,
                    unit: "°C",
                    trend: getTemperatureTrend()
                )
                .onTapGesture {
                    selectedSensor = "temperature"
                }
                
                SensorCard(
                    title: "Вологість",
                    value: String(format: "%.0f%%", humidity),
                    icon: "humidity",
                    color: .blue,
                    unit: "%",
                    trend: getHumidityTrend()
                )
                .onTapGesture {
                    selectedSensor = "humidity"
                }
            }
            
            // Датчик освітленості на всю ширину
            SensorCard(
                title: "Освітленість",
                value: "\(lightLevel)%",
                icon: "sun.max.fill",
                color: .yellow,
                isFullWidth: true,
                unit: "%"
            )
            .onTapGesture {
                selectedSensor = "light"
            }
            
            // Детальна інформація
            if showingDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    DetailRow(
                        label: "Мінімум",
                        value: String(format: "%.1f°C", temperature - 2),
                        icon: "arrow.down",
                        color: .blue
                    )
                    
                    DetailRow(
                        label: "Максимум",
                        value: String(format: "%.1f°C", temperature + 2),
                        icon: "arrow.up",
                        color: .red
                    )
                    
                    DetailRow(
                        label: "Комфорт",
                        value: getComfortLevel(),
                        icon: "face.smiling",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .sheet(item: $selectedSensor) { sensor in
            SensorDetailView(sensor: sensor, temperature: temperature, humidity: humidity, lightLevel: lightLevel)
        }
    }
    
    private func getTemperatureTrend() -> SensorCard.Trend {
        // Тут має бути логіка визначення тренду
        return .stable
    }
    
    private func getHumidityTrend() -> SensorCard.Trend {
        // Тут має бути логіка визначення тренду
        return .stable
    }
    
    private func getComfortLevel() -> String {
        if temperature > 25 && humidity > 60 {
            return "Спекотно"
        } else if temperature < 18 && humidity < 40 {
            return "Холодно"
        } else {
            return "Комфортно"
        }
    }
}

// Детальний рядок
struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(color)
        }
        .font(.caption)
    }
}

// Детальний перегляд датчика
struct SensorDetailView: View {
    let sensor: String
    let temperature: Double
    let humidity: Double
    let lightLevel: Int
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                switch sensor {
                case "temperature":
                    TemperatureDetailView(temperature: temperature)
                case "humidity":
                    HumidityDetailView(humidity: humidity)
                case "light":
                    LightDetailView(lightLevel: lightLevel)
                default:
                    EmptyView()
                }
            }
            .navigationTitle(titleForSensor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var titleForSensor: String {
        switch sensor {
        case "temperature": return "Температура"
        case "humidity": return "Вологість"
        case "light": return "Освітленість"
        default: return ""
        }
    }
}

// Детальний перегляд температури
struct TemperatureDetailView: View {
    let temperature: Double
    
    var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 20) {
                    Text(String(format: "%.1f°C", temperature))
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(temperatureColor)
                    
                    Text(temperatureStatus)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
        
        Section("Історія") {
            // Тут має бути графік історії
            Text("Графік зміни температури")
        }
    }
    
    private var temperatureColor: Color {
        switch temperature {
        case ..<10: return .blue
        case 10..<18: return .cyan
        case 18..<24: return .green
        case 24..<30: return .orange
        default: return .red
        }
    }
    
    private var temperatureStatus: String {
        switch temperature {
        case ..<10: return "Холодно"
        case 10..<18: return "Прохолодно"
        case 18..<24: return "Оптимально"
        case 24..<30: return "Тепло"
        default: return "Спекотно"
        }
    }
}

// Детальний перегляд вологості
struct HumidityDetailView: View {
    let humidity: Double
    
    var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 20) {
                    Text(String(format: "%.0f%%", humidity))
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(humidityColor)
                    
                    Text(humidityStatus)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private var humidityColor: Color {
        switch humidity {
        case ..<30: return .red
        case 30..<50: return .orange
        case 50..<70: return .green
        default: return .blue
        }
    }
    
    private var humidityStatus: String {
        switch humidity {
        case ..<30: return "Сухо"
        case 30..<50: return "Помірно"
        case 50..<70: return "Комфортно"
        default: return "Волого"
        }
    }
}

// Детальний перегляд освітленості
struct LightDetailView: View {
    let lightLevel: Int
    
    var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 20) {
                    Text("\(lightLevel)%")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(lightColor)
                    
                    Text(lightStatus)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private var lightColor: Color {
        switch lightLevel {
        case ..<20: return .gray
        case 20..<50: return .yellow
        case 50..<80: return .orange
        default: return .red
        }
    }
    
    private var lightStatus: String {
        switch lightLevel {
        case ..<20: return "Темно"
        case 20..<50: return "Світло"
        case 50..<80: return "Яскраво"
        default: return "Дуже яскраво"
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}

struct GeneralSensorsSection_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSensorsSection(
            temperature: 23.5,
            humidity: 65,
            lightLevel: 75
        )
        .padding()
    }
}
