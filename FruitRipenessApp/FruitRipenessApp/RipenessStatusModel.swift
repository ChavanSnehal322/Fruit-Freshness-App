//
//  RipeStatus.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

 
import SwiftUI

// MARK: - Ripeness Status Enum
enum RipenessStatus: String {
    case unripe = "Unripe"
    case partiallyRipe = "Partially Ripe"
    case ripe = "Ripe"
    case overripe = "Overripe"
    
    var color: Color {
        switch self {
        case .unripe: return .green
        case .partiallyRipe: return .yellow
        case .ripe: return .orange
        case .overripe: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .unripe: return "leaf.fill"
        case .partiallyRipe: return "sun.max.fill"
        case .ripe: return "checkmark.circle.fill"
        case .overripe: return "exclamationmark.triangle.fill"
        }
    }
}

//
//#Preview {
//    RipeStatus()
//}
