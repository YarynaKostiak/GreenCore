//
//  SoilMoistureIndicator.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct SoilMoistureIndicator: View {
    let value: Int
    let index: Int
    var showLabel: Bool = true
    var isActive: Bool = false
    
    var color: Color {
        switch value {
        case 0..<20:
            return .red
        case 20..<40:
            return .orange
        case 40..<60:
            return .yellow
        case 60..<80:
            return .green
        default:
            return .blue
        }
    }
    
    var statusText: String {
        switch value {
        case 0..<20:
            return "Критично сухо"
        case 20..<40:
            return "Сухо"
        case 40..<60:
            return "Помірно"
        case 60..<80:
            return "Волого"
        default:
            return "Перезволожено"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Індикатор
            ZStack(alignment: .bottom) {
                // Фон
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 100)
                
                // Рівень вологи
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 36, height: CGFloat(value))
                
                // Анімація поливу
                if isActive {
                    WaterWave(height: CGFloat(value))
                        .frame(width: 36, height: CGFloat(value))
                        .opacity(0.3)
                }
                
                // Розмітка
                VStack(spacing: 18) {
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 30, height: 1)
                    }
                }
                .offset(y: -50)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            if showLabel {
                VStack(spacing: 4) {
                    Text("Датчик #\(index + 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(value)%")
                        .font(.headline)
                        .foregroundColor(color)
                        .contentTransition(.numericText())
                    
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            } else {
                Text("\(value)%")
                    .font(.caption)
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: value)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// Хвиля для анімації поливу
struct WaterWave: Shape {
    var height: CGFloat
    var phase: Double = 0
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midHeight = rect.height
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 4 + phase * 5)
            let y = midHeight + sine * 5
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: midHeight))
        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// Горизонтальний індикатор
struct HorizontalSoilMoistureIndicator: View {
    let value: Int
    let index: Int
    
    var color: Color {
        switch value {
        case 0..<20: return .red
        case 20..<40: return .orange
        case 40..<60: return .yellow
        case 60..<80: return .green
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Ґрунт #\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(value)%")
                    .font(.caption)
                    .bold()
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: value)
    }
}

// Компактний індикатор для списку
struct CompactSoilMoistureIndicator: View {
    let value: Int
    let index: Int
    
    var body: some View {
        HStack {
            Text("🌱 #\(index + 1)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 6)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(moistureColor)
                    .frame(width: CGFloat(value) / 2, height: 6)
            }
            
            Text("\(value)%")
                .font(.caption2)
                .foregroundColor(moistureColor)
        }
    }
    
    private var moistureColor: Color {
        switch value {
        case 0..<30: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }
}

struct SoilMoistureIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                SoilMoistureIndicator(value: 25, index: 0)
                SoilMoistureIndicator(value: 65, index: 1)
                SoilMoistureIndicator(value: 85, index: 2, isActive: true)
            }
            
            HorizontalSoilMoistureIndicator(value: 45, index: 0)
            HorizontalSoilMoistureIndicator(value: 75, index: 1)
            
            CompactSoilMoistureIndicator(value: 30, index: 0)
            CompactSoilMoistureIndicator(value: 80, index: 1)
        }
        .padding()
    }
}
