//
//  FilterType.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import CoreImage


enum FilterType: String, CaseIterable {
    case original, vintage, blackAndWhite, warm, cool, fade, grain
    case analogNegative, analogPositive
    case polaroid, sepia
    // Premium filters
    case cinematic, lomography
    case portra400, portra800
    case kodachrome, ektachrome
    case fujiSuperior, fujiAcros
    
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .vintage: return "Vintage"
        case .blackAndWhite: return "B&W"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .fade: return "Fade"
        case .grain: return "Grain"
        case .analogNegative: return "Negative"
        case .analogPositive: return "Positive"
        case .polaroid: return "Polaroid"
        case .sepia: return "Sepia"
        // Premium filters
        case .cinematic: return "Cinematic"
        case .lomography: return "Lomography"
        case .portra400: return "Portra 400"
        case .portra800: return "Portra 800"
        case .kodachrome: return "Kodachrome"
        case .ektachrome: return "Ektachrome"
        case .fujiSuperior: return "Fuji Superior"
        case .fujiAcros: return "Fuji Acros"
        }
    }
}
