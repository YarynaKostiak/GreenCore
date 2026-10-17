//
//  ControlsView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation
import CoreBluetooth

struct ControlsView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var showingBluetoothAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Тільки пошук пристроїв, без перемикача
                DeviceDiscoveryView(bluetoothManager: bluetoothManager)
            }
            .navigationTitle("Пошук пристроїв")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowBluetoothPermissionAlert"))) { _ in
            showingBluetoothAlert = true
        }
        .alert("Доступ до Bluetooth", isPresented: $showingBluetoothAlert) {
            Button("Відкрити налаштування") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Скасувати", role: .cancel) { }
        } message: {
            Text("Додатку потрібен доступ до Bluetooth. Будь ласка, дозвольте доступ в налаштуваннях.")
        }
    }
}

// MARK: - DeviceDiscoveryView
struct DeviceDiscoveryView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var isRefreshing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Інформація про Bluetooth
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Доступні пристрої")
                            .font(.headline)
                        
                        Spacer()
                        
                        if bluetoothManager.isScanning {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Сканування...")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: refreshScan) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        }
                        .disabled(bluetoothManager.isScanning)
                    }
                    
                    HStack {
                        Circle()
                            .fill(bluetoothManager.isConnected ? Color.green :
                                  bluetoothManager.isScanning ? Color.yellow : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(bluetoothManager.connectionStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                )
                
                // Якщо підключено - показуємо інформацію про підключений пристрій
                if bluetoothManager.isConnected {
                    ConnectedDeviceInfoView(bluetoothManager: bluetoothManager)
                }
                
                // Список пристроїв
                if bluetoothManager.discoveredPeripherals.isEmpty {
                    EmptyStateView()
                } else {
                    ForEach(bluetoothManager.discoveredPeripherals) { device in
                        DeviceRowView(
                            device: device,
                            isConnected: bluetoothManager.connectedPeripheral?.identifier == device.peripheral.identifier,
                            onConnect: {
                                bluetoothManager.connect(to: device)
                            }
                        )
                    }
                    
                    if bluetoothManager.isScanning {
                        Button("Зупинити пошук") {
                            bluetoothManager.stopScanning()
                        }
                        .foregroundColor(.red)
                        .padding()
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if !bluetoothManager.isScanning && !bluetoothManager.isConnected {
                bluetoothManager.startScanning()
            }
        }
    }
    
    private func refreshScan() {
        withAnimation(.linear(duration: 0.5)) {
            isRefreshing = true
        }
        
        bluetoothManager.stopScanning()
        bluetoothManager.discoveredPeripherals.removeAll()
        bluetoothManager.startScanning()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                isRefreshing = false
            }
        }
    }
}

// MARK: - ConnectedDeviceInfoView (додано для відображення підключеного пристрою)
struct ConnectedDeviceInfoView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Підключено до пристрою")
                    .font(.headline)
                
                Spacer()
                
                Button("Відключити") {
                    bluetoothManager.disconnect()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(6)
            }
            
            if let peripheral = bluetoothManager.connectedPeripheral {
                HStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.green)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(peripheral.name ?? "ESP32_AutoWater")
                            .font(.subheadline)
                            .bold()
                        
                        Text("Активне з'єднання")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.green, lineWidth: 1)
                )
        )
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding()
            
            Text("Пристрої не знайдено")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Переконайтеся, що Bluetooth увімкнено\nта пристрій знаходиться поруч")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - DeviceRowView
struct DeviceRowView: View {
    let device: DiscoveredPeripheral
    let isConnected: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            // Іконка
            ZStack {
                Circle()
                    .fill(deviceColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: deviceIcon)
                    .font(.title2)
                    .foregroundColor(deviceColor)
            }
            
            // Інформація
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    // Індикатор сигналу
                    HStack(spacing: 2) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(index < device.signalStrength.bars ? device.signalStrength.color : Color.gray.opacity(0.3))
                                .frame(width: 3, height: CGFloat(5 + index * 3))
                        }
                    }
                    
                    Text("\(abs(device.rssi)) dBm")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Статус/Кнопка
            if isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Підключено")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: onConnect) {
                    Text("Підключити")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isConnected ? Color.green : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var deviceColor: Color {
        if isConnected { return .green }
        switch device.signalStrength {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        }
    }
    
    private var deviceIcon: String {
        if device.name.lowercased().contains("farm") {
            return "leaf.fill"
        } else if device.name.lowercased().contains("sensor") {
            return "sensor"
        } else {
            return "antenna.radiowaves.left.and.right"
        }
    }
}

#Preview {
    ControlsView(bluetoothManager: BluetoothManager())
}
