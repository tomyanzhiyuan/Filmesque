//
//  SubscriptionView.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var purchaseError: Error?
    @State private var showError = false
    @State private var isRestoring = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground).opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Premium icon and title
                        VStack(spacing: 10) {
                            Image(systemName: "star.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.yellow)
                                .padding()
                            
                            Text("Upgrade to Premium")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Unlock all premium film filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Feature list
                        VStack(alignment: .leading, spacing: 15) {
                            FeatureRow(iconName: "film.fill", title: "10+ Premium Film Filters", description: "Including Portra, Kodachrome, and more")
                            FeatureRow(iconName: "slider.horizontal.3", title: "Advanced Adjustments", description: "Fine-tune your film effects with precision")
                            FeatureRow(iconName: "photo.fill", title: "High Resolution Export", description: "Save your photos in maximum quality")
                            FeatureRow(iconName: "ray", title: "Remove Watermark", description: "Clean, professional look for your images")
                            FeatureRow(iconName: "arrow.clockwise", title: "Regular Updates", description: "New filters added regularly")
                        }
                        .padding(.horizontal, 20)
                        
                        // Purchase button
                        if !purchaseManager.products.isEmpty {
                            let product = purchaseManager.products.first!
                            
                            Button(action: {
                                performPurchase(product: product)
                            }) {
                                HStack {
                                    Text("Unlock Premium")
                                    Spacer()
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Text(product.displayPrice)
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                            }
                            .disabled(isPurchasing || isRestoring)
                        } else {
                            Text("Loading product information...")
                                .foregroundColor(.secondary)
                        }
                        
                        // Restore purchases
                        Button(action: {
                            restorePurchases()
                        }) {
                            HStack {
                                Text("Restore Purchases")
                                if isRestoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding(.leading, 5)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                        .disabled(isPurchasing || isRestoring)
                        .padding(.top, 5)
                        
                        // Terms and privacy
                        VStack(spacing: 5) {
                            Text("By purchasing, you agree to our Terms of Service and Privacy Policy.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Purchase Failed"),
                    message: Text(purchaseError?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onDisappear {
            // Reset purchase state when view is dismissed
            isPurchasing = false
            isRestoring = false
        }
    }
    
    private func performPurchase(product: Product) {
        isPurchasing = true
        
        Task {
            do {
                if let transaction = try await purchaseManager.purchase(product) {
                    // Purchase was successful, transaction exists
                    if transaction.productID == PurchaseManager.proUpgradeID {
                        // Handle successful purchase (update UI, unlock features, etc.)
                        dismiss()
                    }
                }
                
                await MainActor.run {
                    isPurchasing = false
                }
            } catch {
                await MainActor.run {
                    purchaseError = error
                    showError = true
                    isPurchasing = false
                }
            }
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        
        Task {
            do {
                try await purchaseManager.restorePurchases()
                
                // If successfully restored and is pro, dismiss the view
                if purchaseManager.isPro {
                    dismiss()
                }
                
                await MainActor.run {
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    purchaseError = error
                    showError = true
                    isRestoring = false
                }
            }
        }
    }
}


