//
//  BluetoothManager.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import CoreBluetooth
import Combine
import SwiftUI

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var sensorData: SensorData?
    @Published var isConnected = false
    @Published var connectionStatus = "Ініціалізація Bluetooth..."
    @Published var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var isScanning = false
    @Published var connectedPeripheral: CBPeripheral?
    @Published var bluetoothState: CBManagerState = .unknown
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var dataCharacteristic: CBCharacteristic?
    private var controlCharacteristic: CBCharacteristic?
    private let notificationService = NotificationService.shared
    private var previousWaterLevel: Int = 100
    private var retryCount = 0
    private let maxRetries = 3
    
    // MARK: - UUIDs (з ESP32)
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let dataCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    private let controlCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")
    
    override init() {
        super.init()
        print("📱 BluetoothManager ініціалізовано")
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        print("🔍 startScanning() викликано, стан: \(centralManager.state.rawValue)")
        
        switch centralManager.state {
        case .poweredOn:
            print("✅ Bluetooth УВІМКНЕНО - ПОЧИНАЄМО СКАНУВАННЯ!")
            discoveredPeripherals.removeAll()
            isScanning = true
            connectionStatus = "🔍 Сканування..."
            
            centralManager.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.isScanning == true {
                    self?.stopScanning()
                    if self?.discoveredPeripherals.isEmpty == true {
                        self?.connectionStatus = "❌ Пристрої не знайдено"
                        print("❌ ЖОДНОГО пристрою не знайдено за 10 секунд")
                    } else {
                        self?.connectionStatus = "✅ Знайдено \(self?.discoveredPeripherals.count ?? 0) пристроїв"
                    }
                }
            }
            
        case .poweredOff:
            print("❌ Bluetooth ВИМКНЕНО")
            connectionStatus = "❌ Увімкніть Bluetooth в налаштуваннях"
            
        case .unauthorized:
            print("⚠️ Bluetooth НЕ АВТОРИЗОВАНО")
            connectionStatus = "❌ Дозвольте доступ до Bluetooth в налаштуваннях"
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowBluetoothPermissionAlert"),
                    object: nil
                )
            }
            
        case .unsupported:
            print("❌ Bluetooth НЕ ПІДТРИМУЄТЬСЯ")
            connectionStatus = "❌ Bluetooth не підтримується"
            
        case .resetting:
            print("🔄 Bluetooth ПЕРЕЗАВАНТАЖУЄТЬСЯ")
            connectionStatus = "🔄 Bluetooth перезавантажується..."
            
        case .unknown:
            print("❓ Bluetooth СТАН НЕВІДОМИЙ")
            connectionStatus = "⏳ Активація Bluetooth..."
            
            if retryCount < maxRetries {
                retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.startScanning()
                }
            }
            
        @unknown default:
            print("❓ НЕВІДОМИЙ СТАН")
            connectionStatus = "⏳ Очікування..."
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        print("🛑 Сканування зупинено")
    }
    
    func connect(to device: DiscoveredPeripheral) {
        print("🔌 Спроба підключення до: \(device.name)")
        connectionStatus = "📲 Підключення до \(device.name)..."
        
        centralManager.connect(device.peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            print("⚠️ Немає підключеного пристрою")
            return
        }
        
        print("🔌 Відключення від: \(peripheral.name ?? "пристрою")")
        centralManager.cancelPeripheralConnection(peripheral)
        connectedPeripheral = nil
        isConnected = false
        connectionStatus = "Відключено"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.startScanning()
        }
    }
    
    // MARK: - Відправка команд на ESP32
    
    // Команда для LED стрічки першого ярусу (RGB лампа)
    func sendRGBLightCommand(red: Double, green: Double, blue: Double, enabled: Bool) {
        sendLightCommand(type: "rgb", red: red, green: green, blue: blue, enabled: enabled)
    }
    
    // Команда для LED стрічки другого ярусу (RGB стрічка)
    func sendStripLightCommand(red: Double, green: Double, blue: Double, enabled: Bool) {
        sendLightCommand(type: "strip", red: red, green: green, blue: blue, enabled: enabled)
    }
    
    // Загальний метод для відправки команд освітлення
    private func sendLightCommand(type: String, red: Double, green: Double, blue: Double, enabled: Bool) {
        guard let characteristic = controlCharacteristic,
              let peripheral = connectedPeripheral else {
            print("❌ Неможливо відправити команду: немає підключення")
            return
        }
        
        // Формуємо JSON для ESP32
        let command: [String: Any] = [
            "type": type,
            "enabled": enabled,
            "r": Int(red),
            "g": Int(green),
            "b": Int(blue),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command)
            peripheral.writeValue(jsonData, for: characteristic, type: .withResponse)
            print("📤 Відправлено \(type) команду: enabled=\(enabled), R=\(Int(red)), G=\(Int(green)), B=\(Int(blue))")
        } catch {
            print("❌ Помилка створення JSON: \(error)")
        }
    }
    
    func sendRelayCommand(relayIndex: Int, state: Bool) {
        guard let characteristic = controlCharacteristic,
              let peripheral = connectedPeripheral else {
            print("❌ Неможливо відправити команду: немає підключення або controlCharacteristic")
            connectionStatus = "❌ Помилка відправки команди"
            return
        }
        
        let command: [String: Any] = [
            "type": "relay",
            "index": relayIndex,
            "state": state,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command)
            peripheral.writeValue(jsonData, for: characteristic, type: .withResponse)
            print("📤 Відправлено команду реле #\(relayIndex): \(state ? "ON" : "OFF")")
            connectionStatus = "📤 Команда відправлена"
        } catch {
            print("❌ Помилка створення JSON: \(error)")
        }
    }
    
    func requestData() {
        guard let characteristic = dataCharacteristic,
              let peripheral = connectedPeripheral else {
            print("❌ Немає dataCharacteristic для читання")
            return
        }
        
        if characteristic.properties.contains(.read) {
            peripheral.readValue(for: characteristic)
            print("📤 Запит даних відправлено")
        } else {
            if let controlChar = controlCharacteristic {
                let command: [String: Any] = [
                    "type": "request",
                    "timestamp": Date().timeIntervalSince1970
                ]
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: command)
                    peripheral.writeValue(jsonData, for: controlChar, type: .withResponse)
                    print("📤 Запит даних відправлено через control characteristic")
                } catch {
                    print("❌ Помилка створення JSON: \(error)")
                }
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        
        let stateString: String
        switch central.state {
        case .poweredOn:
            stateString = "🟢 УВІМКНЕНО"
            print("✅ Bluetooth готовий до роботи")
            connectionStatus = "Bluetooth увімкнено"
            retryCount = 0
            startScanning()
            
        case .poweredOff:
            stateString = "🔴 ВИМКНЕНО"
            connectionStatus = "❌ Увімкніть Bluetooth в налаштуваннях"
            discoveredPeripherals.removeAll()
            isConnected = false
            isScanning = false
            
            if isConnected {
                notificationService.sendConnectionLostNotification()
            }
            
        case .unauthorized:
            stateString = "⚠️ НЕ АВТОРИЗОВАНО"
            connectionStatus = "❌ Дозвольте доступ до Bluetooth"
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowBluetoothPermissionAlert"),
                    object: nil
                )
            }
            
        case .unsupported:
            stateString = "❌ НЕ ПІДТРИМУЄТЬСЯ"
            connectionStatus = "❌ Bluetooth не підтримується"
            
        case .resetting:
            stateString = "🔄 СКИДАЄТЬСЯ"
            connectionStatus = "🔄 Bluetooth перезавантажується..."
            
        case .unknown:
            stateString = "❓ НЕВІДОМИЙ"
            connectionStatus = "⏳ Активація Bluetooth..."
            
        @unknown default:
            stateString = "❓ НЕВІДОМИЙ"
            connectionStatus = "⏳ Очікування..."
        }
        
        print("📡 Bluetooth стан: \(stateString)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("\n🔵🔵🔵🔵🔵 ЗНАЙДЕНО ПРИСТРІЙ! 🔵🔵🔵🔵🔵")
        print("📱 Ім'я (peripheral.name): \(peripheral.name ?? "nil")")
        print("📱 Ім'я (advertisementData): \(advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "nil")")
        print("📱 UUID: \(peripheral.identifier.uuidString)")
        print("📱 RSSI: \(RSSI) dBm")
        
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            print("📱 Service UUIDs: \(serviceUUIDs)")
        }
        
        let deviceName = peripheral.name ??
                         advertisementData[CBAdvertisementDataLocalNameKey] as? String ??
                         "ESP32 #\(peripheral.identifier.uuidString.prefix(4))"
        
        DispatchQueue.main.async {
            if let index = self.discoveredPeripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                self.discoveredPeripherals[index].rssi = RSSI.intValue
                self.discoveredPeripherals[index].lastSeen = Date()
                print("🔄 Оновлено: \(deviceName)")
            } else {
                let discovered = DiscoveredPeripheral(
                    peripheral: peripheral,
                    name: deviceName,
                    rssi: RSSI.intValue,
                    lastSeen: Date()
                )
                self.discoveredPeripherals.append(discovered)
                print("✅ ДОДАНО НОВИЙ ПРИСТРІЙ: \(deviceName)")
                print("📊 Всього пристроїв у списку: \(self.discoveredPeripherals.count)")
            }
            
            self.discoveredPeripherals.sort { $0.rssi > $1.rssi }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Підключено до: \(peripheral.name ?? "пристрій")")
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        isConnected = true
        connectionStatus = "✅ Підключено до \(peripheral.name ?? "пристрій")"
        stopScanning()
        
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Відключено від: \(peripheral.name ?? "пристрій")")
        
        if let error = error {
            print("❌ Помилка відключення: \(error.localizedDescription)")
        }
        
        if connectedPeripheral?.identifier == peripheral.identifier {
            isConnected = false
            connectedPeripheral = nil
            dataCharacteristic = nil
            controlCharacteristic = nil
            connectionStatus = "Відключено"
            
            notificationService.sendConnectionLostNotification()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.startScanning()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Помилка підключення до: \(peripheral.name ?? "пристрій")")
        if let error = error {
            print("❌ Деталі: \(error.localizedDescription)")
        }
        connectionStatus = "❌ Помилка підключення"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.startScanning()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Помилка пошуку сервісів: \(error)")
            return
        }
        
        guard let services = peripheral.services else {
            print("⚠️ Сервіси не знайдено")
            return
        }
        
        for service in services {
            print("🔧 Знайдено сервіс: \(service.uuid)")
            if service.uuid == serviceUUID {
                print("✅ Знайдено потрібний сервіс!")
                peripheral.discoverCharacteristics([dataCharacteristicUUID, controlCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Помилка пошуку характеристик: \(error)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("⚠️ Характеристики не знайдено")
            return
        }
        
        for characteristic in characteristics {
            print("⚙️ Знайдено характеристику: \(characteristic.uuid)")
            print("   Властивості: \(characteristic.properties.rawValue)")
            
            // Характеристика для отримання даних (NOTIFY) - без READ
            if characteristic.uuid == dataCharacteristicUUID {
                dataCharacteristic = characteristic
                
                // Підписуємося на нотифікації, навіть якщо READ недоступний
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("📥 Підписано на отримання даних (NOTIFY)")
                    connectionStatus = "📥 Очікування даних..."
                } else {
                    print("⚠️ Характеристика не підтримує NOTIFY")
                }
            }
            
            // Характеристика для відправки команд (WRITE)
            if characteristic.uuid == controlCharacteristicUUID {
                controlCharacteristic = characteristic
                print("📤 Знайдено характеристику для керування (WRITE)")
                
                if characteristic.properties.contains(.write) {
                    print("   ✅ Підтримує запис з відповіддю")
                }
                if characteristic.properties.contains(.writeWithoutResponse) {
                    print("   ✅ Підтримує запис без відповіді")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Помилка отримання даних: \(error)")
            return
        }
        
        guard let data = characteristic.value else {
            print("⚠️ Дані відсутні")
            return
        }
        
        if let dataString = String(data: data, encoding: .utf8) {
            print("📊 ОТРИМАНО ДАНІ: \(dataString)")
        }
        
        let result = DataParser.parseSensorData(data)
        
        DispatchQueue.main.async {
            switch result {
            case .success(let sensorData):
                print("✅ ПАРСИНГ УСПІШНИЙ:")
                print("   🌡️ Температура: \(sensorData.temperature)°C")
                print("   💧 Вологість: \(sensorData.humidity)%")
                print("   ☀️ Освітленість: \(sensorData.lightLevel)%")
                print("   💦 Рівень води: \(sensorData.waterLevel)%")
                print("   🌱 Ґрунт 1: \(sensorData.soilMoisture1)")
                print("   🌱 Ґрунт 2: \(sensorData.soilMoisture2)")
                print("   🔌 Реле: \(sensorData.relays)")
                
                if sensorData.waterLevel < 30 && self.previousWaterLevel >= 30 {
                    print("⚠️ НИЗЬКИЙ РІВЕНЬ ВОДИ!")
                    self.notificationService.sendWaterLevelNotification(level: sensorData.waterLevel)
                }
                self.previousWaterLevel = sensorData.waterLevel
                self.sensorData = sensorData
                self.connectionStatus = "✅ Дані оновлено"
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("BluetoothDataUpdated"),
                    object: nil,
                    userInfo: [
                        "soilMoisture1": sensorData.soilMoisture1,
                        "soilMoisture2": sensorData.soilMoisture2,
                        "relays": sensorData.relays
                    ]
                )
                
            case .failure(let error):
                print("❌ ПОМИЛКА ПАРСИНГУ: \(error)")
                self.connectionStatus = "⚠️ Помилка даних"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Помилка запису: \(error.localizedDescription)")
            connectionStatus = "❌ Помилка відправки"
        } else {
            print("✅ Команду успішно відправлено на ESP32")
            connectionStatus = "✅ Команда виконана"
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Помилка оновлення нотифікацій: \(error)")
        } else {
            print("📢 Нотифікації \(characteristic.isNotifying ? "УВІМКНЕНО" : "ВИМКНЕНО") для \(characteristic.uuid)")
        }
    }
}

// MARK: - Модель для відображення пристроїв
struct DiscoveredPeripheral: Identifiable {
    let id = UUID()
    let peripheral: CBPeripheral
    var name: String
    var rssi: Int
    var lastSeen: Date
    
    var signalStrength: SignalStrength {
        switch rssi {
        case -50...0:
            return .excellent
        case -70 ..< -50:
            return .good
        case -90 ..< -70:
            return .fair
        default:
            return .poor
        }
    }
    
    var signalPercentage: Int {
        let minRSSI = -100
        let maxRSSI = -30
        let clampedRSSI = max(minRSSI, min(maxRSSI, rssi))
        return 100 - (abs(clampedRSSI - maxRSSI) * 100 / (abs(maxRSSI - minRSSI)))
    }
}

enum SignalStrength {
    case excellent, good, fair, poor
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        }
    }
    
    var bars: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Відмінний"
        case .good: return "Добрий"
        case .fair: return "Середній"
        case .poor: return "Слабкий"
        }
    }
}
