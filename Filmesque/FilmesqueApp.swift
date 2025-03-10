//
//  FilmesqueApp.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import SwiftUI

@main
struct FilmFilterApp: App {
    // App-wide state using StateObject for the main view model
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var purchaseManager = PurchaseManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoViewModel)
                .environmentObject(purchaseManager)
        }
    }
}
