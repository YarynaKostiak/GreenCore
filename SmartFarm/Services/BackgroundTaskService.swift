//
//  BackgroundTaskService.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import BackgroundTasks

class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    private let taskIdentifier = "com.smartfarm.watercheck"
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleWaterLevelCheck(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleWaterLevelCheck() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 хвилин
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Не вдалося запланувати задачу: \(error)")
        }
    }
    
    private func handleWaterLevelCheck(task: BGAppRefreshTask) {
        // Планую наступну перевірку
        scheduleWaterLevelCheck()
        
        // Створюємо операцію для перевірки рівня води
        let operation = BlockOperation {
            // Тут логіка перевірки через Bluetooth
            // Якщо рівень низький - відправляємо сповіщення
            NotificationService.shared.sendWaterLevelNotification(level: 25)
        }
        
        task.expirationHandler = {
            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        OperationQueue().addOperation(operation)
    }
}
