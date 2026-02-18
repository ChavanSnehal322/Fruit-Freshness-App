//
//  AuthManager.swift
//  FruitRipenessApp
//
//  Created by Snehal Chavan on 2/11/26.
//

 
import Foundation
import Combine  // ← IMPORTANT: This was missing!
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        checkAuthStatus()
    }
    
    // MARK: - Check Auth Status
    func checkAuthStatus() {
        if let currentUser = auth.currentUser {
            self.user = currentUser
            self.isAuthenticated = true
            print("✅ User logged in: \(currentUser.email ?? "no email")")
        } else {
            self.isAuthenticated = false
            print("⚠️ No user logged in")
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Create user document in Firestore
            try await db.collection("users").document(result.user.uid).setData([
                "email": email,
                "displayName": displayName,
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            
            print("✅ User created: \(email)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            
            await MainActor.run {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            
            print("✅ User signed in: \(email)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
        
        self.user = nil
        self.isAuthenticated = false
        self.errorMessage = nil
        
        print("✅ User signed out")
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
        print("✅ Password reset email sent to: \(email)")
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = auth.currentUser else { return }
        
        // Delete user data from Firestore
        try await db.collection("users").document(user.uid).delete()
        
        // Delete user account
        try await user.delete()
        
        await MainActor.run {
            self.user = nil
            self.isAuthenticated = false
        }
        
        print("✅ User account deleted")
    }
    
    // MARK: - Save Scan to Firestore
    func saveScan(_ analysis: FruitAnalysis) async throws {
        guard let userId = user?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let scanData: [String: Any] = [
            "fruitName": analysis.fruitName,
            "ripenessPercentage": analysis.ripenessPercentage,
            "status": analysis.status.rawValue,
            "daysUntilPeak": analysis.daysUntilPeak,
            "consumeByDate": Timestamp(date: analysis.consumeByDate),
            "timestamp": Timestamp(date: analysis.timestamp),
            "storageRecommendation": analysis.storageRecommendation
        ]
        
        try await db.collection("users")
            .document(userId)
            .collection("scans")
            .document(analysis.id.uuidString)
            .setData(scanData)
        
        print("✅ Scan saved to Firestore")
    }
    
    // MARK: - Load Scans from Firestore
    func loadScans() async throws -> [FruitAnalysis] {
        guard let userId = user?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("scans")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        let scans = snapshot.documents.compactMap { doc -> FruitAnalysis? in
            let data = doc.data()
            
            guard let fruitName = data["fruitName"] as? String,
                  let ripenessPercentage = data["ripenessPercentage"] as? Int,
                  let statusRaw = data["status"] as? String,
                  let status = RipenessStatus(rawValue: statusRaw),
                  let daysUntilPeak = data["daysUntilPeak"] as? Int,
                  let consumeByTimestamp = data["consumeByDate"] as? Timestamp,
                  let timestamp = data["timestamp"] as? Timestamp,
                  let storageRecommendation = data["storageRecommendation"] as? String else {
                return nil
            }
            
            // Create a placeholder image (actual images would need to be stored separately)
            let placeholderImage = UIImage(systemName: "photo") ?? UIImage()
            
            return FruitAnalysis(
                fruitName: fruitName,
                ripenessPercentage: ripenessPercentage,
                status: status,
                daysUntilPeak: daysUntilPeak,
                consumeByDate: consumeByTimestamp.dateValue(),
                image: placeholderImage,
                timestamp: timestamp.dateValue(),
                storageRecommendation: storageRecommendation
            )
        }
        
        print("✅ Loaded \(scans.count) scans from Firestore")
        return scans
    }
}
