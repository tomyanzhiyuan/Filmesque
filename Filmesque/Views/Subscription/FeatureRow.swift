//
//  FeatureRow.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import StoreKit

struct FeatureRow: View {
    let iconName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
