//
//  FruitViewModel.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

import Foundation
import SwiftUI
import Combine
import CoreML
import Vision
import CoreImage
import UserNotifications

class FruitsViewModel: ObservableObject {
    
    @Published var scanHistory: [FruitAnalysis] = []
    @Published var currentAnalysis: FruitAnalysis?
    
    private var mlModel: MLModel?
    
    init() {
        setupModel()
    }
    
    private let fruitDatabase: [String: FruitInfo] = [
        "banana": FruitInfo(shelfLife: 5, peakDays: 2, storage: "Room temperature, refrigerate when ripe"),
        "apple": FruitInfo(shelfLife: 14, peakDays: 3, storage: "Refrigerate for best quality"),
        "avocado": FruitInfo(shelfLife: 4, peakDays: 1, storage: "Room temp to ripen, then refrigerate"),
        "tomato": FruitInfo(shelfLife: 7, peakDays: 2, storage: "Room temperature, never refrigerate"),
        "strawberry": FruitInfo(shelfLife: 5, peakDays: 1, storage: "Refrigerate immediately"),
        "orange": FruitInfo(shelfLife: 10, peakDays: 3, storage: "Room temp or refrigerate"),
        "mango": FruitInfo(shelfLife: 5, peakDays: 2, storage: "Room temp to ripen, then refrigerate"),
        "peach": FruitInfo(shelfLife: 5, peakDays: 2, storage: "Room temp to ripen, then refrigerate"),
        "pear": FruitInfo(shelfLife: 7, peakDays: 2, storage: "Room temp to ripen, then refrigerate"),
        "grape": FruitInfo(shelfLife: 7, peakDays: 2, storage: "Refrigerate in vented bag"),
        "dragon fruit": FruitInfo(shelfLife: 5, peakDays: 2, storage: "Refrigerate when ripe"),
        "durian": FruitInfo(shelfLife: 3, peakDays: 1, storage: "Refrigerate immediately")
    ]
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            if let modelURL = Bundle.main.url(forResource: "fruitRipenessModel", withExtension: "mlmodelc") {
                self.mlModel = try MLModel(contentsOf: modelURL, configuration: config)
                print("✅ ML Model loaded")
            } else {
                let model = try fruitRipenessModel(configuration: config)
                self.mlModel = model.model
                print("✅ ML Model loaded from source")
            }
            
        } catch {
            print("❌ Model loading failed: \(error.localizedDescription)")
            self.mlModel = nil
        }
    }
    
    func analyzeFruit(image: UIImage) {
        if let model = mlModel {
            analyzeFruitWithML(image: image, model: model)
        } else {
            print("⚠️ No ML model, using simulation")
            analyzeFruitSimulated(image: image)
        }
    }
    
    // MARK: - ML Prediction
    private func analyzeFruitWithML(image: UIImage, model: MLModel) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Get input name
                let inputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "image"
                
                // Use standard size for Image Feature Print models
                let targetWidth = 299
                let targetHeight = 299
                
                // Create pixel buffer
                guard let cgImage = image.cgImage else {
                    throw NSError(domain: "ML", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get CGImage"])
                }
                
                let pixelBuffer = try self.createPixelBuffer(
                    from: cgImage,
                    width: targetWidth,
                    height: targetHeight
                )
                
                // Create input
                let inputValue = MLFeatureValue(pixelBuffer: pixelBuffer)
                let inputProvider = try MLDictionaryFeatureProvider(dictionary: [inputName: inputValue])
                
                print("🔄 Making prediction...")
                
                // Predict
                let prediction = try model.prediction(from: inputProvider)
                
                print("✅ Prediction successful!")
                
                // Extract label
                var label = ""
                var confidence: Float = 0.8
                
                // Try "target" (Image Feature Print models)
                if let targetLabel = prediction.featureValue(for: "target")?.stringValue {
                    label = targetLabel
                    if let probs = prediction.featureValue(for: "targetProbability")?.dictionaryValue as? [String: Double] {
                        confidence = Float(probs[label] ?? 0.8)
                    }
                }
                // Try "classLabel" (older models)
                else if let classLabel = prediction.featureValue(for: "classLabel")?.stringValue {
                    label = classLabel
                    if let probs = prediction.featureValue(for: "classLabelProbs")?.dictionaryValue as? [String: Double] {
                        confidence = Float(probs[label] ?? 0.8)
                    }
                }
                
                guard !label.isEmpty else {
                    throw NSError(domain: "ML", code: 2, userInfo: [NSLocalizedDescriptionKey: "No label found"])
                }
                
                print("🎯 Prediction: \(label) (\(Int(confidence * 100))%)")
                
                DispatchQueue.main.async {
                    self.processMLResult(identifier: label, confidence: confidence, image: image)
                }
                
            } catch {
                print("❌ Prediction failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.analyzeFruitSimulated(image: image)
                }
            }
        }
    }
    
    // MARK: - Create Pixel Buffer
    private func createPixelBuffer(from cgImage: CGImage, width: Int, height: Int) throws -> CVPixelBuffer {
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "ML", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"])
        }
        
        let lockFlags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(buffer, lockFlags)
        
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, lockFlags)
            throw NSError(domain: "ML", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        CVPixelBufferUnlockBaseAddress(buffer, lockFlags)
        
        return buffer
    }
    
    // MARK: - Process ML Result
    private func processMLResult(identifier: String, confidence: Float, image: UIImage) {
        let normalized = identifier.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .trimmingCharacters(in: .whitespaces)
        
        var fruitName = "Unknown"
        var ripenessLabel = "ripe"
        
        if normalized.contains("_") {
            let parts = normalized.split(separator: "_")
            if parts.count >= 2 {
                fruitName = String(parts[0]).capitalized
                ripenessLabel = parts[1...].joined(separator: "_")
            }
        } else if normalized.contains("ripe") {
            if normalized.contains("overripe") {
                ripenessLabel = "overripe"
                fruitName = normalized.replacingOccurrences(of: "overripe", with: "").trimmingCharacters(in: .whitespaces).capitalized
            } else if normalized.contains("unripe") {
                ripenessLabel = "unripe"
                fruitName = normalized.replacingOccurrences(of: "unripe", with: "").trimmingCharacters(in: .whitespaces).capitalized
            } else {
                ripenessLabel = "ripe"
                fruitName = normalized.replacingOccurrences(of: "ripe", with: "").trimmingCharacters(in: .whitespaces).capitalized
            }
        } else {
            fruitName = normalized.capitalized
        }
        
        print("🍎 Detected: \(fruitName) - \(ripenessLabel)")
        
        let (status, percentage) = parseRipeness(ripenessLabel, confidence: confidence)
        let fruitKey = fruitName.lowercased()
        let fruitInfo = fruitDatabase[fruitKey] ?? FruitInfo(shelfLife: 7, peakDays: 2, storage: "Store in cool place")
        let (daysUntilPeak, consumeByDays) = calculateTimeline(status: status, fruitInfo: fruitInfo)
        let consumeByDate = Calendar.current.date(byAdding: .day, value: consumeByDays, to: Date()) ?? Date()
        
        let analysis = FruitAnalysis(
            fruitName: fruitName,
            ripenessPercentage: percentage,
            status: status,
            daysUntilPeak: daysUntilPeak,
            consumeByDate: consumeByDate,
            image: image,
            timestamp: Date(),
            storageRecommendation: fruitInfo.storage
        )
        
        self.currentAnalysis = analysis
        self.scanHistory.insert(analysis, at: 0)
        scheduleWastageReminder(for: analysis)
    }
    
    private func parseRipeness(_ label: String, confidence: Float) -> (status: RipenessStatus, percentage: Int) {
        let normalized = label.lowercased()
        
        let (status, basePercentage): (RipenessStatus, Int) = {
            if normalized.contains("overripe") {
                return (.overripe, 95)
            } else if normalized.contains("unripe") {
                return confidence < 0.75 ? (.partiallyRipe, 45) : (.unripe, 25)
            } else if normalized.contains("ripe") {
                return confidence < 0.75 ? (.partiallyRipe, 65) : (.ripe, 80)
            } else {
                return (.partiallyRipe, 50)
            }
        }()
        
        let adjustment = Int((confidence - 0.5) * 10)
        let final = max(0, min(100, basePercentage + adjustment))
        
        return (status, final)
    }
    
    private func analyzeFruitSimulated(image: UIImage) {
        print("⚠️ Using simulation mode")
        
        let fruits = ["Banana", "Apple", "Mango", "Strawberry", "Grape", "Tomato", "Avocado"]
        let fruitName = fruits.randomElement() ?? "Banana"
        let ripenessPercentage = Int.random(in: 20...95)
        let status = determineRipenessStatus(percentage: ripenessPercentage)
        
        let fruitKey = fruitName.lowercased()
        let fruitInfo = fruitDatabase[fruitKey] ?? FruitInfo(shelfLife: 7, peakDays: 2, storage: "Store in cool place")
        
        let (daysUntilPeak, consumeByDays) = calculateTimeline(status: status, fruitInfo: fruitInfo)
        let consumeByDate = Calendar.current.date(byAdding: .day, value: consumeByDays, to: Date()) ?? Date()
        
        let analysis = FruitAnalysis(
            fruitName: fruitName,
            ripenessPercentage: ripenessPercentage,
            status: status,
            daysUntilPeak: daysUntilPeak,
            consumeByDate: consumeByDate,
            image: image,
            timestamp: Date(),
            storageRecommendation: fruitInfo.storage
        )
        
        self.currentAnalysis = analysis
        self.scanHistory.insert(analysis, at: 0)
        scheduleWastageReminder(for: analysis)
    }
    
    func clearHistory() {
        scanHistory.removeAll()
    }
    
    func deleteScan(at offsets: IndexSet) {
        scanHistory.remove(atOffsets: offsets)
    }
    
    private func determineRipenessStatus(percentage: Int) -> RipenessStatus {
        switch percentage {
        case 0..<40: return .unripe
        case 40..<70: return .partiallyRipe
        case 70..<85: return .ripe
        default: return .overripe
        }
    }
    
    private func calculateTimeline(status: RipenessStatus, fruitInfo: FruitInfo) -> (daysUntilPeak: Int, consumeByDays: Int) {
        switch status {
        case .unripe:
            return (fruitInfo.peakDays, fruitInfo.shelfLife)
        case .partiallyRipe:
            return (max(1, fruitInfo.peakDays - 1), fruitInfo.shelfLife - 1)
        case .ripe:
            return (0, max(2, fruitInfo.shelfLife / 2))
        case .overripe:
            return (0, 1)
        }
    }
    
    func scheduleWastageReminder(for analysis: FruitAnalysis) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "🍎 Eat your \(analysis.fruitName)!"
            content.body = "Your \(analysis.fruitName) is at peak ripeness!"
            content.sound = .default
            
            let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: analysis.consumeByDate) ?? Date()
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
}
