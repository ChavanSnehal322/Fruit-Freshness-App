//
//  Otherviews.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

import SwiftUI
 
// MARK: - Recent Scan Card
struct RecentScanCard: View
{
    let analysis: FruitAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(uiImage: analysis.image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(analysis.fruitName)
                .font(.subheadline.bold())
            
            HStack(spacing: 4) {
                Image(systemName: analysis.status.icon)
                    .font(.caption)
                Text("\(analysis.ripenessPercentage)%")
                    .font(.caption)
            }
            .foregroundColor(analysis.status.color)
        }
        .frame(width: 120)
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
    }
}

// MARK: - Timeline Card
struct TimelineCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body.bold())
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let analysis: FruitAnalysis
    
    var body: some View {
        HStack(spacing: 15) {
            Image(uiImage: analysis.image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.fruitName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: analysis.status.icon)
                        Text("\(analysis.ripenessPercentage)%")
                    }
                    .font(.subheadline)
                    .foregroundColor(analysis.status.color)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(analysis.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews
struct ComponentViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InfoCard(
                icon: "chart.bar.fill",
                title: "Smart Analysis",
                description: "AI-powered ripeness detection"
            )
            .previewLayout(.sizeThatFits)
            .padding()
            
            TimelineCard(
                icon: "calendar.badge.clock",
                title: "Days Until Peak",
                value: "2 days",
                color: .orange
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
