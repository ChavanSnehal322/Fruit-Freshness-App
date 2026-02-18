//
//  Historyview.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

import SwiftUI

struct HistoryView: View
{
 
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FruitsViewModel
    
    var body: some View
    {
       
        NavigationView
        {
            List {
                ForEach(viewModel.scanHistory) { scan in
                    HistoryRow(analysis: scan)
                }
                .onDelete(perform: viewModel.deleteScan)
            }
            .navigationTitle("Scan History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.scanHistory.isEmpty {
                        Button("Clear All") {
                            viewModel.clearHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.scanHistory.isEmpty {
                    EmptyHistoryView()
                }
            }
        }
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Scans Yet")
                .font(.title2.bold())
            
            Text("Start scanning fruits to build your history")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(viewModel: FruitsViewModel())
    }
}
 
