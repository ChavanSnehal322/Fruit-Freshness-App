//
//  Analyzingview.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

import SwiftUI

struct AnalyzingView: View
{
    @State private var rotation: Double = 0
    
    var body: some View
    {
        VStack(spacing: 30)
        {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .rotationEffect(.degrees(rotation))
                .onAppear
                    {
                        withAnimation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false)
                        ) {
                            rotation = 360
                    }
                }
            
            Text("Analyzing Ripeness...")
                .font(.title2.bold())
            
            Text("Using AI to detect freshness")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
}

    // MARK: - Preview
    struct AnalyzingView_Previews: PreviewProvider {
        static var previews: some View {
            AnalyzingView()
        }
    }
 
