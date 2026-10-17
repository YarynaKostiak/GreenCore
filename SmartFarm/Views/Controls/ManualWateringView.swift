//
//  ManualWateringView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct ManualWateringView: View {
    @ObservedObject var bluetoothManager: BluetoothManager  // ДОДАНО
    @State private var selectedTier = 0
    @State private var selectedPump = 0
    @State private var duration: Double = 5
    @State private var isWatering = false
    @State private var showingConfirmation = false
    @State private var wateringProgress: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок
            HStack {
                ZStack {
                    Circle()
                        .fill(bluetoothManager.isConnected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                        .foregroundColor(bluetoothManager.isConnected ? .green : .gray)
                }
                
                Text("Ручний полив")
                    .font(.headline)
                
                Spacer()
                
                // Статус підключення
                Circle()
                    .fill(bluetoothManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                // Індикатор поливу
                if isWatering {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Полив...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if !bluetoothManager.isConnected {
                Text("❌ Немає підключення до ESP32")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Вибір ярусу
            VStack(alignment: .leading, spacing: 8) {
                Text("Виберіть ярус")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Ярус", selection: $selectedTier) {
                    Text("Перший ярус").tag(0)
                    Text("Другий ярус").tag(1)
                }
                .pickerStyle(.segmented)
                .disabled(!bluetoothManager.isConnected || isWatering)
            }
            
            // Вибір насоса
            VStack(alignment: .leading, spacing: 8) {
                Text("Виберіть насос")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(0..<2, id: \.self) { index in
                        PumpButton(
                            number: index + 1,
                            isSelected: selectedPump == index,
                            isActive: isWatering && selectedPump == index,
                            isConnected: bluetoothManager.isConnected
                        ) {
                            selectedPump = index
                        }
                    }
                }
            }
            
            // Вибір тривалості
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Тривалість поливу")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(duration)) хв")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                }
                
                Slider(value: $duration, in: 1...30, step: 1)
                    .accentColor(.green)
                    .disabled(!bluetoothManager.isConnected || isWatering)
                
                // Шкала часу
                HStack {
                    Text("1 хв")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("15 хв")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("30 хв")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Прогрес поливу
            if isWatering {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Прогрес")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(wateringProgress * 100))%")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.green)
                    }
                    
                    ProgressView(value: wateringProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
                .padding(.top, 8)
            }
            
            // Кнопка запуску/зупинки
            Button(action: {
                if isWatering {
                    stopWatering()
                } else {
                    showingConfirmation = true
                }
            }) {
                HStack {
                    Image(systemName: isWatering ? "stop.fill" : "play.fill")
                    Text(isWatering ? "Зупинити полив" : "Почати полив")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    !bluetoothManager.isConnected ? Color.gray :
                    (isWatering ? Color.red : Color.green)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            }
            .disabled(!bluetoothManager.isConnected)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .alert("Підтвердження поливу", isPresented: $showingConfirmation) {
            Button("Скасувати", role: .cancel) { }
            Button("Почати") {
                startWatering()
            }
        } message: {
            Text("Почати полив \(selectedTier == 0 ? "першого" : "другого") ярусу, насос #\(selectedPump + 1) на \(Int(duration)) хвилин?")
        }
        .onDisappear {
            stopWatering()
        }
    }
    
    private func startWatering() {
        isWatering = true
        wateringProgress = 0
        
        // Відправка команди на Bluetooth
        let relayIndex = selectedTier * 2 + selectedPump
        bluetoothManager.sendRelayCommand(relayIndex: relayIndex, state: true)
        
        // Симуляція прогресу поливу
        let totalTime = duration * 60
        let interval = 0.1
        let steps = totalTime / interval
        let increment = 1.0 / steps
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if wateringProgress < 1.0 {
                wateringProgress += increment
            } else {
                stopWatering()
            }
        }
        
        print("📱 Початок поливу: ярус \(selectedTier), насос \(selectedPump + 1), тривалість \(duration) хв")
    }
    
    private func stopWatering() {
        timer?.invalidate()
        timer = nil
        isWatering = false
        wateringProgress = 0
        
        // Відправка команди на Bluetooth для зупинки
        let relayIndex = selectedTier * 2 + selectedPump
        bluetoothManager.sendRelayCommand(relayIndex: relayIndex, state: false)
        
        print("📱 Полив зупинено")
    }
}

// Кнопка вибору насоса
struct PumpButton: View {
    let number: Int
    let isSelected: Bool
    let isActive: Bool
    let isConnected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)
                    
                    if isActive {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "drop.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "drop")
                            .font(.title2)
                            .foregroundColor(isSelected ? .white : (isConnected ? .gray : Color.gray.opacity(0.5)))
                    }
                }
                
                Text("Насос #\(number)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : (isConnected ? .secondary : Color.gray.opacity(0.5)))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .disabled(!isConnected)
    }
    
    private var backgroundColor: Color {
        if !isConnected {
            return Color.gray.opacity(0.1)
        } else if isActive {
            return .blue
        } else if isSelected {
            return .green
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

struct ManualWateringView_Previews: PreviewProvider {
    static var previews: some View {
        ManualWateringView(bluetoothManager: BluetoothManager())
            .padding()
    }
}
