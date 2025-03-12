//
//  FilterThumbnail.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import StoreKit

struct FilterThumbnail: View {
    let filter: FilterPreset
    let isSelected: Bool
    var isLocked: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                // Filter preview image
                if let previewImage = filter.previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .opacity(isLocked ? 0.5 : 1.0)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                }
                
                // Lock icon for premium filters
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 70, height: 70)
                }
            }
            
            Text(filter.name)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .primary)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}
