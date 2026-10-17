//
//  NotificationService.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject {
    static let shared = NotificationService()
    
    override init() {
        super.init()
        requestAuthorization()
        setupNotificationCategories()
    }
    
//    MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Дозвіл на сповіщення отримано")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Помилка отримання дозволу: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Setup
    private func setupNotificationCategories() {
        // Категорія для сповіщень про воду
        let waterCategory = UNNotificationCategory(
            identifier: "WATER_ALERT",
            actions: [
                UNNotificationAction(identifier: "CHECK_ACTION", title: "Перевірити", options: .foreground),
                UNNotificationAction(identifier: "DISMISS_ACTION", title: "Закрити", options: .destructive)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Категорія для сповіщень про з'єднання
        let connectionCategory = UNNotificationCategory(
            identifier: "CONNECTION_ALERT",
            actions: [
                UNNotificationAction(identifier: "RECONNECT_ACTION", title: "Перепідключити", options: .foreground)
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([waterCategory, connectionCategory])
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Send Notifications
    func sendWaterLevelNotification(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Низький рівень води"
        content.body = "Рівень води становить \(level)%. Будь ласка, долийте воду."
        content.sound = .defaultCritical
        content.badge = 1
        content.categoryIdentifier = "WATER_ALERT"
        
        // Додаємо кастомні дані
        content.userInfo = [
            "type": "water_alert",
            "level": level,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Додаємо вкладення (картинку)
        if let imageURL = Bundle.main.url(forResource: "water_drop", withExtension: "png") {
            do {
                let attachment = try UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                content.attachments = [attachment]
            } catch {
                print("Помилка створення вкладення: \(error)")
            }
        }
        
        // Створюємо тригер для негайної доставки
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Створюємо запит
        let request = UNNotificationRequest(
            identifier: "water_alert_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Відправляємо
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Помилка відправки сповіщення: \(error)")
            }
        }
    }
    
    func sendConnectionLostNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Втрачено з'єднання"
        content.body = "З'єднання з фермою втрачено. Перевірте Bluetooth."
        content.sound = .default
        content.categoryIdentifier = "CONNECTION_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "connection_lost_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendSensorAlertNotification(sensor: String, value: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Попередження датчика"
        content.body = "Датчик \(sensor): \(value)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "sensor_alert_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Scheduled Notifications
    func scheduleDailyWaterCheck() {
        let content = UNMutableNotificationContent()
        content.title = "Перевірка води"
        content.body = "Час перевірити рівень води на фермі"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_water_check",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Remove Notifications
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показуємо сповіщення навіть коли додаток відкритий
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "CHECK_ACTION":
            // Відкрити секцію з водою
            NotificationCenter.default.post(name: NSNotification.Name("OpenWaterSection"), object: nil)
            
        case "RECONNECT_ACTION":
            // Спробувати перепідключитися
            NotificationCenter.default.post(name: NSNotification.Name("ReconnectBluetooth"), object: nil)
            
        case "DISMISS_ACTION":
            // Просто закрити
            break
            
        default:
            break
        }
        
        completionHandler()
    }
}
