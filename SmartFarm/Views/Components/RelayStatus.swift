//
//  RelayStatus.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct RelayStatus: View {
    let isActive: Bool
    let index: Int
    var onToggle: ((Bool) -> Void)?
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Індикатор
            ZStack {
                Circle()
                    .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                if isActive {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.0 : 0.5)
                }
                
                Image(systemName: isActive ? "drop.fill" : "drop")
                    .font(.title3)
                    .foregroundColor(isActive ? .white : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Насос #\(index + 1)")
                    .font(.subheadline)
                    .bold()
                
                Text(isActive ? "Полив активний" : "Очікування")
                    .font(.caption)
                    .foregroundColor(isActive ? .blue : .secondary)
            }
            
            Spacer()
            
            // Перемикач
            if let onToggle = onToggle {
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: isActive ? Color.blue.opacity(0.2) : Color.clear, radius: 5)
        )
        .onAppear {
            if isActive {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            } else {
                isAnimating = false
            }
        }
    }
}

// Компактна версія
struct CompactRelayStatus: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? "drop.fill" : "drop")
                .font(.caption)
                .foregroundColor(isActive ? .blue : .gray)
            
            Text(isActive ? "Полив" : "Очік.")
                .font(.caption2)
                .foregroundColor(isActive ? .blue : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        )
    }
}

struct RelayStatus_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RelayStatus(isActive: true, index: 0)
            RelayStatus(isActive: false, index: 1)
            CompactRelayStatus(isActive: true)
        }
        .padding()
    }
}
