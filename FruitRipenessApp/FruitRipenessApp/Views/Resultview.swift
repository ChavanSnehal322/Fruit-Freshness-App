//
//  Resultview.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

import SwiftUI

struct ResultView: View
{
    
    let analysis: FruitAnalysis
    let onDismiss: () -> Void
    
    var body: some View
    {
       
        ScrollView
        {
            VStack(spacing: 25)
            {
                // Fruit image
                FruitImageView(image: analysis.image)
                
                // Fruit name
                Text(analysis.fruitName)
                    .font(.title.bold())
                
                // Ripeness gauge
                RipenessGaugeView(analysis: analysis)
                
                // Timeline info
                TimelineInfoSection(analysis: analysis)
                
                // Action buttons
                ActionButtonsSection(onDismiss: onDismiss)
            }
        }
    }
}

// MARK: - Fruit Image View
struct FruitImageView: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 250)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
    }
}

// MARK: - Ripeness Gauge View
struct RipenessGaugeView: View {
    let analysis: FruitAnalysis
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(analysis.ripenessPercentage) / 100)
                    .stroke(
                        analysis.status.color,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Center text
                VStack(spacing: 5) {
                    Text("\(analysis.ripenessPercentage)%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(analysis.status.color)
                    Text(analysis.status.rawValue)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Timeline Info Section
struct TimelineInfoSection: View {
    let analysis: FruitAnalysis
    
    var body: some View {
        VStack(spacing: 15) {
            TimelineCard(
                icon: "calendar.badge.clock",
                title: "Days Until Peak",
                value: "\(analysis.daysUntilPeak) days",
                color: .orange
            )
            
            TimelineCard(
                icon: "calendar.badge.exclamationmark",
                title: "Consume By",
                value: formatDate(analysis.consumeByDate),
                color: .red
            )
            
            TimelineCard(
                icon: "thermometer.medium",
                title: "Storage Tip",
                value: analysis.storageRecommendation,
                color: .blue
            )
        }
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Add to calendar or set reminder
            }) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text("Set Reminder")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }
            
            Button(action: onDismiss) {
                Text("Done")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
    }
}

// MARK: - Preview
struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(
            analysis: FruitAnalysis(
                fruitName: "Banana",
                ripenessPercentage: 75,
                status: .ripe,
                daysUntilPeak: 0,
                consumeByDate: Date(),
                image: UIImage(systemName: "photo")!,
                timestamp: Date(),
                storageRecommendation: "Room temperature"
            ),
            onDismiss: {}
        )
    }
}

 
