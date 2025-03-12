//
//  ContentView.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject private var photoViewModel: PhotoViewModel
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            if photoViewModel.selectedImage != nil {
                EditView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("New Photo") {
                                showingImagePicker = true
                            }
                        }
                    }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("Import a photo to begin")
                        .font(.headline)
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text("Select Photo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                    }
                }
                .navigationTitle("Film Filter")
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $photoViewModel.selectedImage)
        }
    }
}

#Preview {
    ContentView()
}
