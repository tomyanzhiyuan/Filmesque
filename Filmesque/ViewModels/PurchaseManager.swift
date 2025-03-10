//
//  PurchaseManager.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import StoreKit
import Combine

class PurchaseManager: ObservableObject {
    enum PurchaseError: Error {
        case failedVerification
        case system(Error)
    }
    
    static let proUpgradeID = "com.yourapp.filmfilter.proupgrade"
    
    @Published var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        // Start listening for transactions right away
        updateListenerTask = listenForTransactions()
        
        // Load products
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // Request products from the App Store
    @MainActor
    func requestProducts() async {
        do {
            // Using await for Product.products in modern syntax
            let storeProducts = try await Product.products(for: [PurchaseManager.proUpgradeID])
            self.products = storeProducts
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // Check transaction history and update purchased products
    @MainActor
    func updatePurchasedProducts() async {
        // Read transaction history
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Update the list of purchased product IDs
                if transaction.revocationDate == nil {
                    self.purchasedProductIDs.insert(transaction.productID)
                } else {
                    self.purchasedProductIDs.remove(transaction.productID)
                }
                
                // Update isPro status
                self.isPro = self.purchasedProductIDs.contains(PurchaseManager.proUpgradeID)
            } catch {
                // Handle transaction verification error
                print("Transaction verification failed: \(error)")
            }
        }
    }
    
    // Purchase a product
    func purchase(_ product: Product) async throws -> Transaction? {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update the list of purchased products locally
                await updatePurchasedProducts()
                
                // Finish the transaction
                await transaction.finish()
                
                return transaction
                
            case .pending:
                // Transaction waiting on external action (like approval)
                return nil
                
            case .userCancelled:
                // User cancelled the transaction
                return nil
                
            default:
                // Unknown or unexpected state
                return nil
            }
        } catch {
            throw PurchaseError.system(error)
        }
    }
    
    // Helper for transaction verification
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // Failed verification
            throw PurchaseError.failedVerification
        case .verified(let safe):
            // Verification succeeded
            return safe
        }
    }
    
    // Listen for transactions from the App Store
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Continuously listen for transactions
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update the list of purchased products
                    await self.updatePurchasedProducts()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    // Handle transaction verification error
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // Restore purchases (for user-initiated restore)
    func restorePurchases() async throws {
        // Simply request the update of purchased products
        await updatePurchasedProducts()
    }
}
