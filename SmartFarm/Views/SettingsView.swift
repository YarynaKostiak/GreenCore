//
//  SettingsView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct SettingsView: View {
    @Binding var isDarkMode: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Тема оформлення")) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .purple : .orange)
                        
                        Toggle(isDarkMode ? "Темна тема" : "Світла тема", isOn: $isDarkMode)
                    }
                }
                
                Section(header: Text("Про додаток")) {
                    HStack {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundColor(.green)
                        Text("Розумна ферма v1.0")
                    }
                    
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text("Розроблено для Smart Farm")
                    }
                }
            }
            .navigationTitle("Налаштування")
        }
    }
}
