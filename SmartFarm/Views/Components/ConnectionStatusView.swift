//
//  ConnectionStatusView.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import SwiftUI
import Combine
import Foundation

struct ConnectionStatusView: View {
    let status: String
    let isConnected: Bool
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            Text(status)
                .font(.subheadline)
            
            Spacer()
            
            if isConnected {
                Button("Відключити", action: {
                    onDisconnect?()
                })
                .font(.caption)
                .foregroundColor(.red)
            } else {
                Button("Пошук", action: {
                    onConnect?()
                })
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
    }
}
