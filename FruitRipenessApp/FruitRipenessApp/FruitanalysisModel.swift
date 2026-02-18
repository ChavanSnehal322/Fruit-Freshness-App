//
//  FruitanalysisModel.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

 
import SwiftUI

// MARK: - Fruit Analysis Model
struct FruitAnalysis: Identifiable {
    
    let id = UUID()
    let fruitName: String
    let ripenessPercentage: Int
    let status: RipenessStatus
    let daysUntilPeak: Int
    let consumeByDate: Date
    let image: UIImage
    let timestamp: Date
    let storageRecommendation: String
}


//#Preview {
//    FruitAnalysis()
//}
