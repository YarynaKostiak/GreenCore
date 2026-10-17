//
//  RGBColor.swift
//  SmartFarm
//
//  Created by Yaryna Kostiak on 20.02.2026.
//

import Foundation
import SwiftUI

struct RGBColor: Codable, Equatable {  // ДОДАНО Equatable
    let red: Double
    let green: Double
    let blue: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    // Реалізація Equatable (Swift може згенерувати автоматично, але можна й вручну)
    static func == (lhs: RGBColor, rhs: RGBColor) -> Bool {
        return lhs.red == rhs.red &&
               lhs.green == rhs.green &&
               lhs.blue == rhs.blue
    }
    
    static let white = RGBColor(red: 1.0, green: 1.0, blue: 1.0)
    static let red = RGBColor(red: 1.0, green: 0.0, blue: 0.0)
    static let green = RGBColor(red: 0.0, green: 1.0, blue: 0.0)
    static let blue = RGBColor(red: 0.0, green: 0.0, blue: 1.0)
    static let yellow = RGBColor(red: 1.0, green: 1.0, blue: 0.0)
    static let purple = RGBColor(red: 1.0, green: 0.0, blue: 1.0)
    static let cyan = RGBColor(red: 0.0, green: 1.0, blue: 1.0)
}
