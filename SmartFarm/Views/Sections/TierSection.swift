//
//  TierSection.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct TierSection: View {
    let title: String
    let tierNumber: Int
    let soilMoisture: [Int]
    let relayStates: [Bool]
    let rgbLight: RGBColor  // Для першого ярусу (RGB лампа)
    let stripLight: RGBColor // Для другого ярусу (RGB стрічка)
    @ObservedObject var bluetoothManager: BluetoothManager
    
    @State private var isExpanded = true
    @State private var showingRGBControl = false
    @State private var showingStripControl = false
    @State private var localRGBLight: RGBColor
    @State private var localStripLight: RGBColor
    @State private var localRelayStates: [Bool]
    @State private var wateringDuration: Double = 5
    @State private var isAutoModeEnabled = false
    @State private var showingDurationPicker = false
    
    // Стани для RGB лампи (перший ярус)
    @State private var isRGBLightEnabled = false
    @State private var rgbRed: Double = 1.0
    @State private var rgbGreen: Double = 1.0
    @State private var rgbBlue: Double = 1.0
    
    // Стани для RGB стрічки (другий ярус)
    @State private var isStripLightEnabled = false
    @State private var stripRed: Double = 1.0
    @State private var stripGreen: Double = 1.0
    @State private var stripBlue: Double = 1.0
    
    @State private var lastCommandStatus = ""
    
    init(title: String, tierNumber: Int, soilMoisture: [Int], relayStates: [Bool], rgbLight: RGBColor, stripLight: RGBColor, bluetoothManager: BluetoothManager) {
        self.title = title
        self.tierNumber = tierNumber
        self.soilMoisture = soilMoisture
        self.relayStates = relayStates
        self.rgbLight = rgbLight
        self.stripLight = stripLight
        self.bluetoothManager = bluetoothManager
        _localRGBLight = State(initialValue: rgbLight)
        _localStripLight = State(initialValue: stripLight)
        _localRelayStates = State(initialValue: relayStates)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок
            HStack {
                SectionHeader(
                    title: title,
                    icon: tierIcon,
                    color: tierColor,
                    showBadge: isAnyRelayActive,
                    badgeValue: activeRelayCount
                )
                
                Spacer()
                
                // Статус підключення
                Circle()
                    .fill(bluetoothManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                // ========== RGB ОСВІТЛЕННЯ ==========
                if tierNumber == 1 {
                    // Перший ярус - RGB лампа
                    rgbLightControl(
                        title: "RGB Лампа",
                        systemImage: "lightbulb.led.fill",
                        isEnabled: $isRGBLightEnabled,
                        red: $rgbRed,
                        green: $rgbGreen,
                        blue: $rgbBlue,
                        onSend: { enabled, r, g, b in
                            bluetoothManager.sendRGBLightCommand(
                                red: r * 255,
                                green: g * 255,
                                blue: b * 255,
                                enabled: enabled
                            )
                        }
                    )
                } else if tierNumber == 2 {
                    // Другий ярус - RGB стрічка
                    rgbLightControl(
                        title: "RGB Стрічка",
                        systemImage: "light.strip.2.fill",
                        isEnabled: $isStripLightEnabled,
                        red: $stripRed,
                        green: $stripGreen,
                        blue: $stripBlue,
                        onSend: { enabled, r, g, b in
                            bluetoothManager.sendStripLightCommand(
                                red: r * 255,
                                green: g * 255,
                                blue: b * 255,
                                enabled: enabled
                            )
                        }
                    )
                }
                
                // Датчики вологості ґрунту
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Вологість ґрунту", systemImage: "drop")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(averageMoisture)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(averageMoistureColor.opacity(0.2))
                            .foregroundColor(averageMoistureColor)
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 20) {
                        ForEach(0..<soilMoisture.count, id: \.self) { index in
                            SoilMoistureIndicator(
                                value: soilMoisture[index],
                                index: index + (tierNumber == 1 ? 0 : 2),
                                isActive: index < localRelayStates.count ? localRelayStates[index] : false
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                
                // Налаштування поливу
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Система автополиву", systemImage: "drop.fill")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("Авто", isOn: $isAutoModeEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .labelsHidden()
                            .disabled(!bluetoothManager.isConnected)
                    }
                    
                    // Налаштування тривалості поливу
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                        
                        Text("Тривалість поливу")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(Int(wateringDuration)) хв")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Button(action: {
                            withAnimation {
                                showingDurationPicker.toggle()
                            }
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if showingDurationPicker {
                        VStack {
                            Slider(value: $wateringDuration, in: 1...30, step: 1)
                                .accentColor(.blue)
                            
                            HStack {
                                Text("1 хв")
                                    .font(.caption2)
                                Spacer()
                                Text("15 хв")
                                    .font(.caption2)
                                Spacer()
                                Text("30 хв")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                    
                    // Статус насосів
                    VStack(spacing: 8) {
                        ForEach(0..<localRelayStates.count, id: \.self) { index in
                            HStack {
                                Image(systemName: localRelayStates[index] ? "drop.fill" : "drop")
                                    .foregroundColor(localRelayStates[index] ? .blue : .gray)
                                
                                Text("Насос #\(index + 1)")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(localRelayStates[index] ? "Активний" : "Неактивний")
                                    .font(.caption)
                                    .foregroundColor(localRelayStates[index] ? .blue : .secondary)
                                
                                if bluetoothManager.isConnected {
                                    Button(action: {
                                        let newState = !localRelayStates[index]
                                        let relayIndex = (tierNumber == 1 ? index : index + 2)
                                        bluetoothManager.sendRelayCommand(relayIndex: relayIndex, state: newState)
                                        localRelayStates[index] = newState
                                    }) {
                                        Text(localRelayStates[index] ? "Вимкнути" : "Увімкнути")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(localRelayStates[index] ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                                            .foregroundColor(localRelayStates[index] ? .red : .green)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: tierColor.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .sheet(isPresented: $showingRGBControl) {
            if tierNumber == 1 {
                ColorPickerView(
                    red: $rgbRed,
                    green: $rgbGreen,
                    blue: $rgbBlue,
                    isLightEnabled: $isRGBLightEnabled,
                    onApply: { enabled, r, g, b in
                        bluetoothManager.sendRGBLightCommand(
                            red: r * 255,
                            green: g * 255,
                            blue: b * 255,
                            enabled: enabled
                        )
                    }
                )
            }
        }
        .sheet(isPresented: $showingStripControl) {
            if tierNumber == 2 {
                ColorPickerView(
                    red: $stripRed,
                    green: $stripGreen,
                    blue: $stripBlue,
                    isLightEnabled: $isStripLightEnabled,
                    onApply: { enabled, r, g, b in
                        bluetoothManager.sendStripLightCommand(
                            red: r * 255,
                            green: g * 255,
                            blue: b * 255,
                            enabled: enabled
                        )
                    }
                )
            }
        }
        .onAppear {
            updateRGBFromData()
            updateStripFromData()
        }
        .onChange(of: rgbLight) { newRGBLight in
            localRGBLight = newRGBLight
            updateRGBFromData()
        }
        .onChange(of: stripLight) { newStripLight in
            localStripLight = newStripLight
            updateStripFromData()
        }
        .onChange(of: relayStates) { newRelayStates in
            localRelayStates = newRelayStates
        }
        .animation(.easeInOut(duration: 0.3), value: isRGBLightEnabled)
        .animation(.easeInOut(duration: 0.3), value: isStripLightEnabled)
    }
    
    // MARK: - RGB Light Control View
    @ViewBuilder
    private func rgbLightControl(
        title: String,
        systemImage: String,
        isEnabled: Binding<Bool>,
        red: Binding<Double>,
        green: Binding<Double>,
        blue: Binding<Double>,
        onSend: @escaping (Bool, Double, Double, Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                
                Spacer()
                
                // Toggle для ввімкнення/вимкнення світла
                Toggle("", isOn: isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    .labelsHidden()
                    .disabled(!bluetoothManager.isConnected)
                    .onChange(of: isEnabled.wrappedValue) { newValue in
                        if newValue {
                            // При ввімкненні встановлюємо білий колір
                            red.wrappedValue = 1.0
                            green.wrappedValue = 1.0
                            blue.wrappedValue = 1.0
                        }
                        onSend(newValue, red.wrappedValue, green.wrappedValue, blue.wrappedValue)
                        lastCommandStatus = newValue ? "💡 Світло увімкнено" : "💡 Світло вимкнено"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            lastCommandStatus = ""
                        }
                    }
                
                // Індикатор поточного кольору
                Circle()
                    .fill(Color(red: red.wrappedValue, green: green.wrappedValue, blue: blue.wrappedValue))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .onTapGesture {
                        if isEnabled.wrappedValue {
                            if title.contains("Лампа") {
                                showingRGBControl = true
                            } else {
                                showingStripControl = true
                            }
                        }
                    }
            }
            
            if !lastCommandStatus.isEmpty {
                Text(lastCommandStatus)
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            
            // Кнопка вибору кольору (тільки якщо світло увімкнено)
            if isEnabled.wrappedValue {
                Button(action: {
                    if title.contains("Лампа") {
                        showingRGBControl = true
                    } else {
                        showingStripControl = true
                    }
                }) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.blue)
                        Text("Обрати колір")
                            .font(.subheadline)
                        Spacer()
                        Text(">")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .disabled(!bluetoothManager.isConnected)
                .transition(.opacity)
            } else {
                Text("Увімкніть світло для вибору кольору")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private func updateRGBFromData() {
        rgbRed = localRGBLight.red
        rgbGreen = localRGBLight.green
        rgbBlue = localRGBLight.blue
        isRGBLightEnabled = !(rgbRed == 0 && rgbGreen == 0 && rgbBlue == 0)
    }
    
    private func updateStripFromData() {
        stripRed = localStripLight.red
        stripGreen = localStripLight.green
        stripBlue = localStripLight.blue
        isStripLightEnabled = !(stripRed == 0 && stripGreen == 0 && stripBlue == 0)
    }
    
    // Допоміжні властивості
    private var tierIcon: String {
        switch tierNumber {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        default: return "3.circle.fill"
        }
    }
    
    private var tierColor: Color {
        switch tierNumber {
        case 1: return .green
        case 2: return .blue
        default: return .purple
        }
    }
    
    private var isAnyRelayActive: Bool {
        localRelayStates.contains(true)
    }
    
    private var activeRelayCount: String {
        let count = localRelayStates.filter { $0 }.count
        return "\(count) актив."
    }
    
    private var averageMoisture: String {
        guard !soilMoisture.isEmpty else { return "0%" }
        let avg = soilMoisture.reduce(0, +) / soilMoisture.count
        return "\(avg)%"
    }
    
    private var averageMoistureColor: Color {
        guard !soilMoisture.isEmpty else { return .gray }
        let avg = soilMoisture.reduce(0, +) / soilMoisture.count
        switch avg {
        case ..<30: return .red
        case 30..<60: return .orange
        default: return .green
        }
    }
}

// MARK: - ColorPickerView
struct ColorPickerView: View {
    @Binding var red: Double
    @Binding var green: Double
    @Binding var blue: Double
    @Binding var isLightEnabled: Bool
    var onApply: (Bool, Double, Double, Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    
    let presets: [(name: String, red: Double, green: Double, blue: Double)] = [
        ("Білий", 1.0, 1.0, 1.0),
        ("Червоний", 1.0, 0.0, 0.0),
        ("Зелений", 0.0, 1.0, 0.0),
        ("Синій", 0.0, 0.0, 1.0),
        ("Жовтий", 1.0, 1.0, 0.0),
        ("Фіолетовий", 1.0, 0.0, 1.0),
        ("Блакитний", 0.0, 1.0, 1.0),
        ("Помаранчевий", 1.0, 0.5, 0.0),
        ("Рожевий", 1.0, 0.75, 0.8),
        ("Теплий білий", 1.0, 0.9, 0.7)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Режим", selection: $selectedTab) {
                    Text("Палітра").tag(0)
                    Text("Пресети").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    // Палітра
                    VStack {
                        ColorWheel(red: $red, green: $green, blue: $blue)
                            .frame(height: 350)
                            .padding()
                        
                        // Слайдери
                        VStack(spacing: 15) {
                            ColorSliderRow(value: $red, color: .red, title: "Червоний")
                            ColorSliderRow(value: $green, color: .green, title: "Зелений")
                            ColorSliderRow(value: $blue, color: .blue, title: "Синій")
                        }
                        .padding()
                        
                        // Попередній перегляд
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(red: red, green: green, blue: blue))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(radius: 5)
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    // Пресети
                    List {
                        ForEach(presets, id: \.name) { preset in
                            Button(action: {
                                applyPreset(preset)
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(red: preset.red, green: preset.green, blue: preset.blue))
                                        .frame(width: 30, height: 30)
                                    
                                    Text(preset.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Вибір кольору")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        applyColor()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func applyPreset(_ preset: (name: String, red: Double, green: Double, blue: Double)) {
        red = preset.red
        green = preset.green
        blue = preset.blue
        applyColor()
    }
    
    private func applyColor() {
        isLightEnabled = true
        onApply(true, red, green, blue)
    }
}

// MARK: - ColorWheel
struct ColorWheel: View {
    @Binding var red: Double
    @Binding var green: Double
    @Binding var blue: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .red, .yellow, .green, .cyan, .blue, .purple, .red
                            ]),
                            center: .center
                        )
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.white, .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width / 2
                        )
                    )
                    .blendMode(.multiply)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        let position = value.location
                        
                        let dx = position.x - center.x
                        let dy = position.y - center.y
                        
                        let distance = sqrt(dx*dx + dy*dy)
                        let maxDistance = geometry.size.width / 2
                        
                        if distance <= maxDistance {
                            let angle = atan2(dy, dx) + .pi
                            let hue = angle / (2 * .pi)
                            let saturation = distance / maxDistance
                            
                            let rgb = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1.0).cgColor.components
                            if let components = rgb, components.count >= 3 {
                                red = Double(components[0])
                                green = Double(components[1])
                                blue = Double(components[2])
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - ColorSliderRow
struct ColorSliderRow: View {
    @Binding var value: Double
    let color: Color
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Slider(value: $value, in: 0...1, step: 0.01)
                .accentColor(color)
            
            Text("\(Int(value * 255))")
                .font(.caption)
                .frame(width: 40)
                .foregroundColor(color)
        }
    }
}

#Preview {
    TierSection(
        title: "Перший ярус",
        tierNumber: 1,
        soilMoisture: [45, 65],
        relayStates: [true, false],
        rgbLight: RGBColor(red: 0.5, green: 0.8, blue: 1.0),
        stripLight: RGBColor(red: 1.0, green: 0.5, blue: 0.8),
        bluetoothManager: BluetoothManager()
    )
}
