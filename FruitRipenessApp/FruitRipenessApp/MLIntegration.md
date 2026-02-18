# Machine Learning Integration Guide

## Overview
This guide shows how to replace the simulated fruit analysis with real ML-powered image recognition.

## Architecture Options

### Option 1: CoreML + Vision (Recommended)
**Pros:**
- On-device processing (privacy)
- Fast inference (<100ms)
- No internet required
- No API costs

**Cons:**
- Requires model training
- Larger app size (~50MB)
- Model updates need app updates

### Option 2: Cloud-based ML (Google Vision AI, AWS Rekognition)
**Pros:**
- No training required
- Always up-to-date
- Smaller app size

**Cons:**
- Requires internet
- API costs
- Privacy concerns
- Slower (network latency)

### Option 3: Hybrid Approach
- Use CoreML for common fruits
- Fallback to cloud for unknown items

## Implementation: CoreML + Vision

### Step 1: Create Training Dataset

You'll need images of fruits at different ripeness levels:

```
Dataset Structure:
├── banana_unripe/       (100+ images)
├── banana_partial/      (100+ images)
├── banana_ripe/         (100+ images)
├── banana_overripe/     (100+ images)
├── apple_unripe/
├── apple_partial/
├── apple_ripe/
└── apple_overripe/
```

**Dataset Sources:**
- Kaggle: "Fruit Recognition Dataset"
- Roboflow: Pre-labeled fruit datasets
- Custom: Photograph fruits over time
- Data augmentation: Rotate, flip, adjust brightness

### Step 2: Train the Model

#### Using Create ML (Easiest)

1. **Open Create ML**
   - Launch from Xcode > Open Developer Tool > Create ML

2. **Create Image Classification Model**
   ```
   File > New Project > Image Classification
   ```

3. **Configure Project**
   - Name: FruitRipenessClassifier
   - Training Data: Select your dataset folder
   - Validation: 20% of data
   - Testing: 10% of data

4. **Set Parameters**
   ```
   Augmentation: ON
   Max Iterations: 25
   Algorithm: Transfer Learning
   Feature Extractor: Vision Feature Print (recommended)
   ```

5. **Train**
   - Click "Train"
   - Wait 10-30 minutes depending on dataset size

6. **Evaluate**
   - Check accuracy (aim for >85%)
   - Review confusion matrix
   - Test with sample images

7. **Export**
   - Output > Export
   - Save as `FruitRipenessModel.mlmodel`

#### Using Python + CreateML Tools (Advanced)

```python
import coremltools as ct
from PIL import Image
import numpy as np

# Your trained TensorFlow/PyTorch model
# Convert to CoreML
coreml_model = ct.convert(
    trained_model,
    inputs=[ct.ImageType(shape=(1, 224, 224, 3))],
    classifier_config=ct.ClassifierConfig(class_labels)
)

# Save
coreml_model.save('FruitRipenessModel.mlmodel')
```

### Step 3: Add Model to Xcode

1. **Drag .mlmodel file** into Xcode project
2. **Select target** membership
3. Xcode auto-generates Swift class

### Step 4: Implement Vision + CoreML

Replace the simulated analysis in `FruitViewModel`:

```swift
import Vision
import CoreML

class FruitViewModel: ObservableObject {
    @Published var scanHistory: [FruitAnalysis] = []
    @Published var currentAnalysis: FruitAnalysis?
    
    private lazy var model: VNCoreMLModel? = {
        do {
            let config = MLModelConfiguration()
            let model = try FruitRipenessModel(configuration: config)
            return try VNCoreMLModel(for: model.model)
        } catch {
            print("Failed to load CoreML model: \(error)")
            return nil
        }
    }()
    
    func analyzeFruit(image: UIImage) {
        guard let model = model else {
            print("Model not available")
            return
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No results or error: \(String(describing: error))")
                return
            }
            
            // Parse result
            self?.processMLResult(topResult, image: image)
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error)")
            }
        }
    }
    
    private func processMLResult(_ result: VNClassificationObservation, image: UIImage) {
        // Parse classifier output
        // Expected format: "banana_ripe", "apple_partial", etc.
        let components = result.identifier.split(separator: "_")
        guard components.count == 2 else { return }
        
        let fruitName = String(components[0]).capitalized
        let ripenessLevel = String(components[1])
        
        // Convert to percentage and status
        let (percentage, status) = getRipenessMetrics(from: ripenessLevel)
        
        // Get fruit-specific info
        let fruitKey = fruitName.lowercased()
        let fruitInfo = fruitDatabase[fruitKey] ?? FruitInfo(
            shelfLife: 7, 
            peakDays: 2, 
            storage: "Store in cool place"
        )
        
        // Calculate timeline
        let (daysUntilPeak, consumeByDays) = calculateTimeline(
            status: status,
            fruitInfo: fruitInfo
        )
        
        let consumeByDate = Calendar.current.date(
            byAdding: .day, 
            value: consumeByDays, 
            to: Date()
        ) ?? Date()
        
        // Create analysis
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
        
        DispatchQueue.main.async {
            self.currentAnalysis = analysis
            self.scanHistory.insert(analysis, at: 0)
        }
    }
    
    private func getRipenessMetrics(from level: String) -> (Int, RipenessStatus) {
        switch level {
        case "unripe":
            return (Int.random(in: 20...39), .unripe)
        case "partial":
            return (Int.random(in: 40...69), .partiallyRipe)
        case "ripe":
            return (Int.random(in: 70...84), .ripe)
        case "overripe":
            return (Int.random(in: 85...95), .overripe)
        default:
            return (50, .partiallyRipe)
        }
    }
    
    private func calculateTimeline(
        status: RipenessStatus,
        fruitInfo: FruitInfo
    ) -> (daysUntilPeak: Int, consumeByDays: Int) {
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
    
    // Keep existing fruitDatabase...
    private let fruitDatabase: [String: FruitInfo] = [
        "banana": FruitInfo(shelfLife: 5, peakDays: 2, storage: "Room temperature, refrigerate when ripe"),
        "apple": FruitInfo(shelfLife: 14, peakDays: 3, storage: "Refrigerate for best quality"),
        // ... rest of database
    ]
}

struct FruitInfo {
    let shelfLife: Int
    let peakDays: Int
    let storage: String
}
```

### Step 5: Improve Model Accuracy

#### Color Analysis
Add Vision request for dominant colors:

```swift
func analyzeColor(_ image: UIImage) -> [UIColor] {
    guard let ciImage = CIImage(image: image) else { return [] }
    
    let request = VNGenerateAttentionBasedSaliencyImageRequest()
    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    
    try? handler.perform([request])
    
    // Extract dominant colors from salient regions
    // Use these to refine ripeness estimate
}
```

#### Texture Analysis
Detect spots, wrinkles, bruises:

```swift
func analyzeTexture(_ image: UIImage) -> Double {
    // Use CIDetector for feature detection
    // More features = likely more ripe/damaged
}
```

#### Multi-model Ensemble
Combine multiple models for better accuracy:

```swift
func ensemblePredict(_ image: UIImage) -> (fruit: String, ripeness: Int) {
    let model1Result = classificationModel.predict(image)
    let model2Result = regressionModel.predict(image)
    let colorScore = colorAnalysis(image)
    
    // Weighted average
    let finalScore = (model1Result * 0.5) + 
                     (model2Result * 0.3) + 
                     (colorScore * 0.2)
    
    return (fruit, Int(finalScore * 100))
}
```

## Advanced Features

### Real-Time Camera Analysis

```swift
import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    @Published var currentPrediction: String = ""
    @Published var confidence: Float = 0
    
    func captureOutput(_ output: AVCaptureOutput, 
                      didOutput sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Run prediction on each frame
        runPrediction(on: pixelBuffer)
    }
    
    private func runPrediction(on pixelBuffer: CVPixelBuffer) {
        // Vision request with pixel buffer
        // Update UI with results
    }
}
```

### Batch Processing

```swift
func analyzeBatch(_ images: [UIImage]) async -> [FruitAnalysis] {
    await withTaskGroup(of: FruitAnalysis?.self) { group in
        for image in images {
            group.addTask {
                return await self.analyzeAsync(image)
            }
        }
        
        var results: [FruitAnalysis] = []
        for await result in group {
            if let analysis = result {
                results.append(analysis)
            }
        }
        return results
    }
}
```

## Model Performance Optimization

### 1. Quantization
Reduce model size by 4x:

```python
import coremltools as ct

# Load model
model = ct.models.MLModel('FruitRipenessModel.mlmodel')

# Quantize to 8-bit
model_quantized = ct.models.neural_network.quantization_utils.quantize_weights(
    model, 
    nbits=8
)

# Save quantized version
model_quantized.save('FruitRipenessModel_Quantized.mlmodel')
```

### 2. Use Neural Engine
Enable for 10x faster inference:

```swift
let config = MLModelConfiguration()
config.computeUnits = .all  // CPU, GPU, Neural Engine

let model = try FruitRipenessModel(configuration: config)
```

### 3. Batch Predictions

```swift
// Process multiple images at once
let batch = try model.predictions(inputs: [input1, input2, input3])
```

## Testing & Validation

### Unit Tests

```swift
import XCTest

class FruitMLTests: XCTestCase {
    func testBananaDetection() {
        let image = UIImage(named: "test_banana")!
        let result = viewModel.analyzeFruit(image)
        
        XCTAssertEqual(result.fruitName, "Banana")
        XCTAssertGreaterThan(result.ripenessPercentage, 0)
    }
    
    func testRipenessAccuracy() {
        // Load test dataset with ground truth
        // Compare predictions with actual labels
        // Assert accuracy > 85%
    }
}
```

### A/B Testing

```swift
struct AnalyticsEvent {
    let modelVersion: String
    let accuracy: Float
    let inferenceTime: TimeInterval
    let userFeedback: Bool // Did user agree?
}

func trackPrediction(_ event: AnalyticsEvent) {
    // Log to analytics service
    // Compare model versions
}
```

## Cloud ML Alternative

### Using Google Cloud Vision

```swift
import GoogleAPIClientForREST

func analyzeWithCloudVision(_ image: UIImage) async throws -> CloudVisionResult {
    let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
    
    let request = GTLRVision_AnnotateImageRequest()
    request.features = [/* fruit detection, label detection */]
    request.image = GTLRVision_Image()
    request.image?.content = base64Image
    
    // Send to Google Cloud Vision API
    // Parse response
}
```

**Pros:** No training needed, always updated
**Cons:** Cost ~$1.50 per 1000 images, requires internet

## Cost Comparison

| Approach | Development Time | Cost per 1000 scans | Accuracy |
|----------|-----------------|---------------------|----------|
| CoreML (Custom) | 2-4 weeks | $0 | 85-95% |
| Google Vision | 1 week | $1.50 | 90-95% |
| AWS Rekognition | 1 week | $1.00 | 85-90% |
| Hybrid | 3-5 weeks | $0.50 | 90-98% |

## Recommended Approach

**For MVP:** Start with CoreML + Create ML
**For Scale:** Hybrid (CoreML + cloud fallback)
**For Enterprise:** Custom CoreML with continuous retraining

## Resources

- [Create ML Documentation](https://developer.apple.com/documentation/createml)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)
- [CoreML Tools](https://coremltools.readme.io/)
- [Kaggle Fruit Datasets](https://www.kaggle.com/datasets?search=fruit)
- [Apple ML Gallery](https://developer.apple.com/machine-learning/models/)

## Next Steps

1. Collect/download training dataset (100+ images per class)
2. Train initial model with Create ML
3. Integrate into app using code above
4. Test with real fruits
5. Collect user feedback
6. Retrain model with new data
7. Repeat until 90%+ accuracy achieved
