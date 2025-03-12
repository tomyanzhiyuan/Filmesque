//
//  FilterPreset.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import CoreImage

struct FilterPreset: Identifiable {
    var id = UUID()
    var name: String
    var filterType: FilterType
    var isPremium: Bool = false
    var parameters: [String: Any] = [:]
    
    var previewImage: UIImage?
    
    // Filter description for UI display
    var description: String {
        "Apply \(name) film effect"
    }
}
