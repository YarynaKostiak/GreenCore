//
//  SmartFarmApp.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import UserNotifications

@main
struct SmartFarmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Ініціалізація при запуску
                    UNUserNotificationCenter.current().setBadgeCount(0)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Реєструємося для push-сповіщень
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        // Обробка запуску зі сповіщення
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            handleNotification(notification)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Відправляємо token на сервер якщо потрібно
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    private func handleNotification(_ userInfo: [String: AnyObject]) {
        // Обробка сповіщення при запуску
        if let type = userInfo["type"] as? String {
            switch type {
            case "water_alert":
                NotificationCenter.default.post(name: NSNotification.Name("OpenWaterSection"), object: nil)
            default:
                break
            }
        }
    }
}
