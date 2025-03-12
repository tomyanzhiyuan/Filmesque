//
//  EditView.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import StoreKit

struct EditView: View {
    @EnvironmentObject private var photoViewModel: PhotoViewModel
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showingSaveConfirmation = false
    @State private var showingSubscriptionView = false
    @State private var saveError: Error?
    @State private var isShowingOriginal = false // to track when the "hold" gesture is active
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Image view area
                ZStack {
                    // Show original image when long press is active, otherwise show filtered image
                    if isShowingOriginal, let originalImage = photoViewModel.selectedImage {
                        Image(uiImage: originalImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                            .overlay(
                                Text("Original Image")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                                    .padding(8),
                                alignment: .top
                            )
                    } else if let filteredImage = photoViewModel.filteredImage { 
                        // Display the filtered image if available, otherwise the original image
                        Image(uiImage: filteredImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                    } else if let originalImage = photoViewModel.selectedImage {
                        Image(uiImage: originalImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                    }
                    
                    // Loading indicator
                    if photoViewModel.isProcessing {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .padding(20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                .background(Color.black.opacity(0.1))
                // Add long press gesture to toggle showing the original image
                .gesture(
                    LongPressGesture(minimumDuration: 0.1)
                        .onChanged { _ in
                            hapticFeedback(.medium)
                            isShowingOriginal = true
                        }
                        .onEnded { _ in
                            isShowingOriginal = false
                        }
                )
                // Optional: Add a hint indicator when the app first launches
                .overlay(
                    Group {
                        if let _ = photoViewModel.filteredImage {
                            Text("Hold to see original")
                                .font(.caption)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                                .padding(8)
                                .opacity(0.8)
                        }
                    },
                    alignment: .bottom
                )
                
                // Controls area
                VStack(spacing: 15) {
                    // Filter intensity slider
                    if photoViewModel.selectedFilter != nil && photoViewModel.selectedFilter?.name != "Original" {
                        HStack {
                            Text("Intensity")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $photoViewModel.filterIntensity, in: 0.0...1.0)
                                .onChange(of: photoViewModel.filterIntensity) { oldValue, newValue in
                                    photoViewModel.applySelectedFilter()
                                }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Filter selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photoViewModel.filterPresets) { filter in
                                // Only show non-premium filters or premium filters if user is Pro
                                if !filter.isPremium || purchaseManager.isPro {
                                    FilterThumbnail(filter: filter, isSelected: photoViewModel.selectedFilter?.id == filter.id)
                                        .onTapGesture {
                                            photoViewModel.selectedFilter = filter
                                            photoViewModel.applySelectedFilter()
                                        }
                                } else {
                                    // Premium filter (locked)
                                    FilterThumbnail(filter: filter, isSelected: false, isLocked: true)
                                        .onTapGesture {
                                            showingSubscriptionView = true
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                    
                    // Bottom buttons
                    HStack(spacing: 20) {
                        // Share button
                        Button(action: {
                            // Share functionality would go here
                        }) {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                Text("Share")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Save button
                        Button(action: {
                            saveImage()
                        }) {
                            VStack {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 22))
                                Text("Save")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Upgrade button
                        if !purchaseManager.isPro {
                            Button(action: {
                                showingSubscriptionView = true
                            }) {
                                VStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 22))
                                    Text("Upgrade")
                                        .font(.caption)
                                }
                                .foregroundColor(.yellow)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                // Reset to original image
                photoViewModel.selectedFilter = photoViewModel.filterPresets.first
                photoViewModel.filterIntensity = 1.0
                photoViewModel.filteredImage = photoViewModel.selectedImage
            }) {
                Text("Reset")
            })
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
            .alert(isPresented: $showingSaveConfirmation) {
                if let error = saveError {
                    return Alert(
                        title: Text("Error"),
                        message: Text("Failed to save image: \(error.localizedDescription)"),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text("Success"),
                        message: Text("Your image has been saved to your photo library."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    private func saveImage() {
        photoViewModel.saveFilteredImage { result in
            switch result {
            case .success:
                saveError = nil
                showingSaveConfirmation = true
            case .failure(let error):
                saveError = error
                showingSaveConfirmation = true
            }
        }
    }
}
