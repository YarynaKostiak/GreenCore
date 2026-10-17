//
//  ContentView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import CoreBluetooth
import Combine
import Foundation

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FarmDashboardView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Ферма", systemImage: "leaf.fill")
                }
                .tag(0)
            
            ControlsView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Керування", systemImage: "slider.horizontal.3")
                }
                .tag(1)
            
            SettingsView(isDarkMode: $isDarkMode)
                .tabItem {
                    Label("Налаштування", systemImage: "gear")
                }
                .tag(2)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .accentColor(.green)
    }
}
