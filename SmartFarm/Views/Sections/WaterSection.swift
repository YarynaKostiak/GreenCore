//
//  WaterSection.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import UserNotifications
import Combine
import Foundation

struct WaterSection: View {
    let waterLevel: Int
    var onLowWater: (() -> Void)?
    @State private var showNotificationSettings = false
    @State private var lastNotificationTime: Date?
    @State private var notificationCooldown = false
    
    var status: WaterLevelStatus {
        switch waterLevel {
        case 0..<30: return .low
        case 30..<70: return .medium
        default: return .high
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Система поливу", icon: "drop.fill")
            
            HStack {
                // Індикатор рівня води
                VStack(alignment: .leading, spacing: 8) {
                    Text("Рівень води")
                        .font(.headline)
                    
                    HStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 100)
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(status.color)
                                .frame(width: 40, height: CGFloat(waterLevel))
                            
                            // Анімація для низького рівня
                            if status == .low {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.5))
                                    .frame(width: 40, height: CGFloat(waterLevel))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(waterLevel)%")
                                .font(.title)
                                .bold()
                            
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundColor(status.color)
                                Text(status == .low ? "Мало води" :
                                     status == .medium ? "Середній рівень" : "Достатньо")
                                    .font(.subheadline)
                                    .foregroundColor(status.color)
                            }
                            
                            // Кнопка налаштувань сповіщень
                            Button(action: {
                                showNotificationSettings = true
                            }) {
                                Label("Налаштувати сповіщення", systemImage: "bell.badge")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.leading)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(status.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(status == .low ? Color.red : Color.clear, lineWidth: 2)
                    )
            )
            
            // Індикатор останнього сповіщення
            if let lastTime = lastNotificationTime {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.caption2)
                    Text("Останнє сповіщення: \(timeAgo(lastTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onChange(of: status) { newStatus in
            if newStatus == .low && !notificationCooldown {
                sendWaterNotification()
            }
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsView()
        }
    }
    
    private func sendWaterNotification() {
        // Запобігаємо спаму сповіщень (раз на 15 хвилин)
        if let lastTime = lastNotificationTime,
           Date().timeIntervalSince(lastTime) < 900 {
            return
        }
        
        lastNotificationTime = Date()
        
        // Блокуємо повторні сповіщення на 5 хвилин
        notificationCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            notificationCooldown = false
        }
        
        // Відправляємо сповіщення через NotificationService
        NotificationService.shared.sendWaterLevelNotification(level: waterLevel)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Налаштування сповіщень
struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("notification_threshold") private var notificationThreshold = 30
    @AppStorage("notification_sound") private var notificationSound = true
    @AppStorage("daily_reminder") private var dailyReminder = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основні налаштування")) {
                    Toggle("Увімкнути сповіщення", isOn: $notificationsEnabled)
                    Toggle("Звук сповіщень", isOn: $notificationSound)
                }
                
                Section(header: Text("Рівень води"), footer: Text("Сповіщення надсилатимуться коли рівень води нижче вказаного значення")) {
                    VStack {
                        Text("Поріг сповіщення: \(notificationThreshold)%")
                        Slider(value: Binding(
                            get: { Double(notificationThreshold) },
                            set: { notificationThreshold = Int($0) }
                        ), in: 10...50, step: 5)
                    }
                }
                
                Section(header: Text("Щоденні нагадування")) {
                    Toggle("Нагадувати перевіряти воду", isOn: $dailyReminder)
                    
                    if dailyReminder {
                        Button("Встановити час нагадування") {
                            // Відкрити вибір часу
                        }
                    }
                }
                
                Section {
                    Button("Тестове сповіщення") {
                        NotificationService.shared.sendWaterLevelNotification(level: 25)
                    }
                    
                    Button("Скинути всі налаштування", role: .destructive) {
                        notificationsEnabled = true
                        notificationThreshold = 30
                        notificationSound = true
                        dailyReminder = false
                        NotificationService.shared.removeAllNotifications()
                    }
                }
            }
            .navigationTitle("Сповіщення")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        // Зберігаємо налаштування
                        if dailyReminder {
                            NotificationService.shared.scheduleDailyWaterCheck()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
