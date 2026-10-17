//
//  SectionHeader.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct SectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .green
    var showBadge: Bool = false
    var badgeValue: String?
    var action: (() -> Void)?
    
    var body: some View {
        HStack {
            // Іконка з градієнтом
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.title3)
                .bold()
            
            Spacer()
            
            // Бейдж
            if showBadge, let badgeValue = badgeValue {
                Text(badgeValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
            }
            
            // Кнопка дії
            if let action = action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// Градієнтна версія
struct GradientSectionHeader: View {
    let title: String
    let icon: String
    let colors: [Color]
    
    var body: some View {
        HStack {
            // Градієнтна іконка
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.title3)
                .bold()
            
            Spacer()
        }
    }
}

// Анімована версія
struct AnimatedSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            Text(title)
                .font(.title3)
                .bold()
            
            Spacer()
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Загальні показники", icon: "thermometer")
            GradientSectionHeader(title: "Перший ярус", icon: "leaf.fill", colors: [.green, .blue])
            AnimatedSectionHeader(title: "Система поливу", icon: "drop.fill", color: .blue)
        }
        .padding()
    }
}
