//
//  SensorCard.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct SensorCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isFullWidth: Bool = false
    var showAnimation: Bool = false
    var unit: String?
    var trend: Trend?
    
    enum Trend {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "equal"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .orange
            }
        }
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .symbolEffect(.bounce, options: .repeating, value: isAnimating)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Тренд
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text("2%")
                            .font(.caption2)
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trend.color.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            
            // Значення
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                    .contentTransition(.numericText())
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Прогрес бар для деяких датчиків
            if title.contains("Вологість") || title.contains("Рівень") {
                ProgressView(value: Double(value.replacingOccurrences(of: "%", with: "")) ?? 0, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(0.8, anchor: .leading)
            }
        }
        .frame(maxWidth: isFullWidth ? .infinity : 160)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            if showAnimation {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

// Компактна версія картки
struct CompactSensorCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .bold()
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
    }
}

struct SensorCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                SensorCard(
                    title: "Температура",
                    value: "23.5°C",
                    icon: "thermometer",
                    color: .orange,
                    unit: "°C",
                    trend: .up
                )
                
                SensorCard(
                    title: "Вологість",
                    value: "65%",
                    icon: "humidity",
                    color: .blue,
                    unit: "%",
                    trend: .down
                )
            }
            
            CompactSensorCard(
                title: "Освітленість",
                value: "75%",
                icon: "sun.max.fill",
                color: .yellow
            )
        }
        .padding()
    }
}
