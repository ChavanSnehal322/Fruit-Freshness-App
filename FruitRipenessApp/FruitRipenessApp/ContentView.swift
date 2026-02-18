//
//  ContentView.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - Main Content View
struct ContentView: View {
    
    @StateObject private var viewModel = FruitsViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var showCamera = false
    @State private var showHistory = false
    @State private var showProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.orange.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    HeaderView()
                    
                    Spacer()
                    
                    // Main action button
                    ScanButton(action: {
                        showCamera = true
                    })
                    
                    // Recent scans
                    if !viewModel.scanHistory.isEmpty {
                        RecentScansSection(
                            scans: viewModel.scanHistory,
                            onViewAll: {
                                showHistory = true
                            }
                        )
                    }
                    
                    // Info cards
                    InfoCardsSection()
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // User greeting
                    if let user = authManager.user {
                        Text("Hello, \(user.displayName ?? "User")!")
                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(viewModel: viewModel)
                    .onDisappear {
                        // Save scan to Firebase after analysis
                        if let analysis = viewModel.currentAnalysis {
                            Task {
                                try? await authManager.saveScan(analysis)
                            }
                        }
                    }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(authManager)
            }
            .onAppear {
                // Load scans from Firebase when view appears
                Task {
                    if let scans = try? await authManager.loadScans() {
                        await MainActor.run {
                            viewModel.scanHistory = scans
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Fruit Freshness")
                .font(.system(size: 32, weight: .bold))
            
            Text("Detect ripeness & reduce waste")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

// MARK: - Scan Button
struct ScanButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                Text("Scan Fruit")
                    .font(.title3.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.orange]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Recent Scans Section
struct RecentScansSection: View {
    let scans: [FruitAnalysis]
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                Spacer()
                Button("View All", action: onViewAll)
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(scans.prefix(5)) { scan in
                        RecentScanCard(analysis: scan)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Info Cards Section
struct InfoCardsSection: View {
    var body: some View {
        VStack(spacing: 12) {
            InfoCard(
                icon: "chart.bar.fill",
                title: "Smart Analysis",
                description: "AI-powered ripeness detection"
            )
            
            InfoCard(
                icon: "calendar.badge.clock",
                title: "Consumption Timeline",
                description: "Know exactly when to eat"
            )
            
            InfoCard(
                icon: "leaf.arrow.circlepath",
                title: "Reduce Waste",
                description: "Save money and the environment"
            )
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
    }
}
