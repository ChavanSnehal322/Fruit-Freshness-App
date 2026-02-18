//
//  FruitRipenessAppApp.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/7/26.
//

 

import SwiftUI
import FirebaseCore

// MARK: - App Delegate (Firebase Configuration)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase configured via AppDelegate")
        return true
    }
}

// MARK: - Main App Entry Point
@main
struct FruitRipenessApp: App {
    
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create AuthManager instance
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            // Show LoginView if not authenticated, otherwise show ContentView
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
