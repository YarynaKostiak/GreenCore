//
//  RelayControlView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct RelayControlView: View {
    let relays: [Bool]
    @ObservedObject var bluetoothManager: BluetoothManager // ДОДАНО
    @State private var selectedTier = 0
    @State private var localRelays: [Bool] = []
    @State private var scheduleEnabled = false
    @State private var autoMode = false
    @State private var showingConfirmation = false
    @State private var lastCommandStatus = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sprinkler.and.droplets")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Керування поливом")
                    .font(.headline)
                
                Spacer()
                
                // Вибір ярусу
                Picker("Ярус", selection: $selectedTier) {
                    Text("1 ярус").tag(0)
                    Text("2 ярус").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            
            // Статус підключення
            HStack {
                Circle()
                    .fill(bluetoothManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(bluetoothManager.isConnected ? "Підключено" : "Немає з'єднання")
                    .font(.caption)
                    .foregroundColor(bluetoothManager.isConnected ? .green : .red)
                
                if !lastCommandStatus.isEmpty {
                    Text("• \(lastCommandStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Перемикачі режимів
            HStack {
                Toggle("Автоматичний", isOn: $autoMode)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .disabled(!bluetoothManager.isConnected)
                
                Toggle("Розклад", isOn: $scheduleEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .disabled(!bluetoothManager.isConnected)
            }
            .font(.caption)
            
            Divider()
            
            // Реле для вибраного ярусу
            if localRelays.indices.contains(selectedTier * 2) {
                ForEach(0..<2, id: \.self) { index in
                    let relayIndex = selectedTier * 2 + index
                    RelayControlItem(
                        title: "Насос #\(relayIndex + 1)",
                        isActive: Binding(
                            get: { localRelays[relayIndex] },
                            set: { newValue in
                                // ОНОВЛЕНО: Використовуємо JSON формат через BluetoothManager
                                if bluetoothManager.isConnected {
                                    localRelays[relayIndex] = newValue
                                    bluetoothManager.sendRelayCommand(relayIndex: relayIndex, state: newValue)
                                    lastCommandStatus = "Команда відправлена"
                                    
                                    // Скидаємо статус через 2 секунди
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        lastCommandStatus = ""
                                    }
                                } else {
                                    showingConfirmation = true
                                }
                            }
                        ),
                        isConnected: bluetoothManager.isConnected
                    )
                }
            }
            
            if scheduleEnabled {
                ScheduleView(bluetoothManager: bluetoothManager)
            }
            
            // Швидкі дії
            HStack {
                Button("Увімкнути всі") {
                    if bluetoothManager.isConnected {
                        for i in selectedTier * 2..<(selectedTier * 2 + 2) {
                            if i < localRelays.count {
                                localRelays[i] = true
                                bluetoothManager.sendRelayCommand(relayIndex: i, state: true)
                            }
                        }
                        lastCommandStatus = "Всі увімкнено"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            lastCommandStatus = ""
                        }
                    } else {
                        showingConfirmation = true
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!bluetoothManager.isConnected)
                
                Button("Вимкнути всі") {
                    if bluetoothManager.isConnected {
                        for i in selectedTier * 2..<(selectedTier * 2 + 2) {
                            if i < localRelays.count {
                                localRelays[i] = false
                                bluetoothManager.sendRelayCommand(relayIndex: i, state: false)
                            }
                        }
                        lastCommandStatus = "Всі вимкнено"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            lastCommandStatus = ""
                        }
                    } else {
                        showingConfirmation = true
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!bluetoothManager.isConnected)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
        .onAppear {
            localRelays = relays
        }
        .onChange(of: relays) { newRelays in
            // Оновлюємо локальний стан при отриманні нових даних з Bluetooth
            localRelays = newRelays
        }
        .alert("Немає підключення", isPresented: $showingConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Для керування насосами потрібне підключення до ESP32")
        }
    }
}

struct RelayControlItem: View {
    let title: String
    @Binding var isActive: Bool
    let isConnected: Bool
    @State private var duration: Double = 5
    @State private var isSending = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Анімована іконка
                ZStack {
                    Image(systemName: isActive ? "drop.fill" : "drop")
                        .foregroundColor(isActive ? .blue : .gray)
                        .scaleEffect(isSending ? 1.3 : 1.0)
                    
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
                
                Text(title)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(isActive ? "Активний" : "Неактивний")
                    .font(.caption)
                    .foregroundColor(isActive ? .blue : .secondary)
                
                Toggle("", isOn: $isActive)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .disabled(!isConnected || isSending)
                    .onChange(of: isActive) { newValue in
                        // Анімація при відправці
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSending = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                isSending = false
                            }
                        }
                    }
            }
            
            if isActive {
                HStack {
                    Text("Тривалість: \(Int(duration)) хв")
                        .font(.caption)
                    
                    Slider(value: $duration, in: 1...30, step: 1)
                        .accentColor(.blue)
                        .disabled(!isConnected)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSending ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

struct ScheduleView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var selectedDays: Set<Int> = []
    @State private var scheduleSaved = false
    
    let days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Розклад поливу")
                .font(.subheadline)
                .bold()
            
            DatePicker("Початок", selection: $startTime, displayedComponents: .hourAndMinute)
                .font(.caption)
            
            DatePicker("Кінець", selection: $endTime, displayedComponents: .hourAndMinute)
                .font(.caption)
            
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    DayButton(
                        day: days[index],
                        isSelected: selectedDays.contains(index)
                    ) {
                        if selectedDays.contains(index) {
                            selectedDays.remove(index)
                        } else {
                            selectedDays.insert(index)
                        }
                    }
                }
            }
            
            Button("Зберегти розклад") {
                saveSchedule()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!bluetoothManager.isConnected)
            
            if scheduleSaved {
                Text("✓ Розклад збережено")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
    }
    
    private func saveSchedule() {
        // Тут можна відправити розклад на ESP32 через BluetoothManager
        // Наприклад, у JSON форматі:
        let schedule: [String: Any] = [
            "type": "schedule",
            "startHour": Calendar.current.component(.hour, from: startTime),
            "startMinute": Calendar.current.component(.minute, from: startTime),
            "endHour": Calendar.current.component(.hour, from: endTime),
            "endMinute": Calendar.current.component(.minute, from: endTime),
            "days": Array(selectedDays)
        ]
        
        // Тут виклик методу для відправки розкладу
        // bluetoothManager.sendSchedule(schedule)
        
        withAnimation {
            scheduleSaved = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                scheduleSaved = false
            }
        }
    }
}

struct DayButton: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption)
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

#Preview {
    RelayControlView(relays: [false, false, false, false], bluetoothManager: BluetoothManager())
}
