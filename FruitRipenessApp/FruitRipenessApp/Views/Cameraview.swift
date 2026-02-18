//
//  Cameraview.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//
 
import SwiftUI

// MARK: - Camera View

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FruitsViewModel
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if let image = capturedImage {
                    if isAnalyzing {
                        AnalyzingView()
                    } else if let analysis = viewModel.currentAnalysis {
                        ResultView(analysis: analysis, onDismiss: {
                            dismiss()
                        })
                    }
                } else {
                    CameraPlaceholderView(
                        onChooseFromLibrary: {
                            showImagePicker = true
                        },
                        onTakePhoto: {
                            // In a real app, this would open the camera
                            // For demo, we'll use image picker
                            showImagePicker = true
                        }
                    )
                }
            }
            .navigationTitle("Scan Fruit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $capturedImage, onImagePicked: {
                    isAnalyzing = true
                    viewModel.analyzeFruit(image: capturedImage!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isAnalyzing = false
                    }
                })
            }
        }
    }
}

// MARK: - Camera Placeholder View
struct CameraPlaceholderView: View {
    let onChooseFromLibrary: () -> Void
    let onTakePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 100))
                .foregroundColor(.green.opacity(0.5))
            
            Text("Capture or Select Photo")
                .font(.title2.bold())
            
            Text("Take a clear photo of your fruit")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: onChooseFromLibrary) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                
                Button(action: onTakePhoto) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(viewModel: FruitsViewModel())
    }
}
 
