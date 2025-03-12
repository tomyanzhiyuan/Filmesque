//
//  PhotoViewModel.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation
import SwiftUI
import CoreImage
import Combine

class PhotoViewModel: ObservableObject {
    // Published properties that automatically update the UI
    @Published var selectedImage: UIImage? {
        didSet {
            if let image = selectedImage {
                currentPhoto = Photo(originalImage: image)
                // Generate small preview images for all filters
                generateFilterPreviews()
            } else {
                currentPhoto = nil
                filteredImage = nil
            }
        }
    }
    
    @Published var currentPhoto: Photo?
    @Published var filteredImage: UIImage?
    @Published var filterPresets: [FilterPreset] = []
    @Published var selectedFilter: FilterPreset?
    @Published var filterIntensity: Double = 1.0
    @Published var isProcessing: Bool = false
    
    // Core Image context (reused for performance)
    private let ciContext = CIContext()
    
    init() {
        setupFilterPresets()
    }
    
    private func setupFilterPresets() {
        // Create all filter presets (both free and premium)
        filterPresets = [
            FilterPreset(name: "Original", filterType: .original, isPremium: false),
            FilterPreset(name: "Vintage", filterType: .vintage, isPremium: false),
            FilterPreset(name: "B&W Classic", filterType: .blackAndWhite, isPremium: false),
            FilterPreset(name: "Warm Tone", filterType: .warm, isPremium: false),
            FilterPreset(name: "Cool Tone", filterType: .cool, isPremium: false),
            FilterPreset(name: "Fade", filterType: .fade, isPremium: false),
            FilterPreset(name: "Grain", filterType: .grain, isPremium: false),
            FilterPreset(name: "Film Negative", filterType: .analogNegative, isPremium: false),
            FilterPreset(name: "Polaroid", filterType: .polaroid, isPremium: false),
            FilterPreset(name: "Sepia", filterType: .sepia, isPremium: false),
            
            // Premium filters, remember to change "isPremium" back to "true" before launching
            FilterPreset(name: "Cinematic", filterType: .cinematic, isPremium: false),
            FilterPreset(name: "Lomography", filterType: .lomography, isPremium: false),
            FilterPreset(name: "Portra 400", filterType: .portra400, isPremium: false),
            FilterPreset(name: "Portra 800", filterType: .portra800, isPremium: false),
            FilterPreset(name: "Kodachrome", filterType: .kodachrome, isPremium: false),
            FilterPreset(name: "Ektachrome", filterType: .ektachrome, isPremium: false),
            FilterPreset(name: "Fuji Superior", filterType: .fujiSuperior, isPremium: false),
            FilterPreset(name: "Fuji Acros", filterType: .fujiAcros, isPremium: false)
        ]
    }
    
    func generateFilterPreviews() {
        guard let image = selectedImage else { return }
        
        // Use a smaller preview image for better performance when generating thumbnails
        let previewImage = image.preparingThumbnail(of: CGSize(width: 300, height: 300))
        
        for i in 0..<filterPresets.count {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                if i == 0 {
                    // Original filter just uses the original image
                    DispatchQueue.main.async {
                        self.filterPresets[i].previewImage = previewImage
                    }
                    return
                }
                
                let filter = self.filterPresets[i]
                let filteredPreview = self.applyFilter(to: previewImage!, filter: filter, intensity: 1.0)
                
                DispatchQueue.main.async {
                    self.filterPresets[i].previewImage = filteredPreview
                }
            }
        }
    }
    
    func applySelectedFilter() {
        guard let photo = currentPhoto, let filter = selectedFilter else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let filtered = self.applyFilter(to: photo.originalImage, filter: filter, intensity: self.filterIntensity)
            
            DispatchQueue.main.async {
                self.filteredImage = filtered
                self.currentPhoto?.filteredImage = filtered
                self.currentPhoto?.appliedFilter = filter
                self.isProcessing = false
            }
        }
    }
    
    func applyFilter(to inputImage: UIImage, filter: FilterPreset, intensity: Double) -> UIImage {
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: inputImage) else { return inputImage }
        
        // Apply different filters based on the filter type
        var outputCIImage: CIImage
        
        switch filter.filterType {
        case .original:
            return inputImage
        case .vintage:
            outputCIImage = applyVintageFilter(to: ciImage)
        case .blackAndWhite:
            outputCIImage = applyBlackAndWhiteFilter(to: ciImage)
        case .warm:
            outputCIImage = applyWarmFilter(to: ciImage)
        case .cool:
            outputCIImage = applyCoolFilter(to: ciImage)
        case .fade:
            outputCIImage = applyFadeFilter(to: ciImage)
        case .grain:
            outputCIImage = applyGrainFilter(to: ciImage)
        case .analogNegative:
            outputCIImage = applyNegativeFilter(to: ciImage)
        case .analogPositive:
            outputCIImage = applyPositiveFilter(to: ciImage)
        case .polaroid:
            outputCIImage = applyPolaroidFilter(to: ciImage)
        case .sepia:
            outputCIImage = applySepiaFilter(to: ciImage)
        // Premium filters
        case .cinematic, .lomography, .portra400, .portra800, .kodachrome, .ektachrome, .fujiSuperior, .fujiAcros:
            outputCIImage = applyPremiumFilter(to: ciImage, filter: filter)
        }
        
        // If intensity is 1.0, return the fully filtered image
        if intensity >= 0.99 {
            if let cgImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) {
                return UIImage(cgImage: cgImage)
            }
            return inputImage
        }
        
        // For all other intensities, blend between original and filtered
        return blendWithOriginal(original: ciImage, filtered: outputCIImage, intensity: intensity)
    }
    
    // Method to handle the blending
    private func blendWithOriginal(original: CIImage, filtered: CIImage, intensity: Double) -> UIImage {
        // Use CIBlendWithMask filter to blend between original and filtered images
        let blend = CIFilter(name: "CIBlendWithMask")
        blend?.setValue(original, forKey: kCIInputBackgroundImageKey)
        blend?.setValue(filtered, forKey: kCIInputImageKey)
        
        // Create a mask image with uniform color representing the intensity
        let maskGenerator = CIFilter(name: "CIConstantColorGenerator")
        maskGenerator?.setValue(CIColor(red: CGFloat(intensity), green: CGFloat(intensity), blue: CGFloat(intensity)), forKey: kCIInputColorKey)
        let mask = maskGenerator?.outputImage?.cropped(to: original.extent)
        
        blend?.setValue(mask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blend?.outputImage else { return UIImage(ciImage: original) }
        
        if let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return UIImage(ciImage: original)
    }
    
    // Filter implementation methods - all without intensity parameter now
    private func applyVintageFilter(to image: CIImage) -> CIImage {
        let sepia = image.applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.7])
        let vignette = sepia.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 0.5,
            kCIInputRadiusKey: 1.5
        ])
        return vignette
    }
    
    private func applyBlackAndWhiteFilter(to image: CIImage) -> CIImage {
        return image.applyingFilter("CIPhotoEffectNoir")
    }
    
    private func applyWarmFilter(to image: CIImage) -> CIImage {
        let warmth = image.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 5000, y: 0)
        ])
        return warmth
    }
    
    private func applyCoolFilter(to image: CIImage) -> CIImage {
        let cool = image.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 8000, y: 0)
        ])
        return cool
    }
    
    private func applyFadeFilter(to image: CIImage) -> CIImage {
        let fade = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.6,  // Fixed value instead of using intensity
            kCIInputBrightnessKey: 0.05,
            kCIInputContrastKey: 0.9
        ])
        return fade
    }
    
    private func applyGrainFilter(to image: CIImage) -> CIImage {
        // Add grain effect using CIRandomGenerator and CISourceOverCompositing
        let randomNoise = CIFilter(name: "CIRandomGenerator")?.outputImage?.cropped(to: image.extent)
        
        guard let noise = randomNoise else { return image }
        
        let grainAmount = 0.1  // Fixed value
        
        let grayscaleNoise = noise.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0),
            "inputGVector": CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0),
            "inputBVector": CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: grainAmount),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])
        
        let combinedImage = image.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: grayscaleNoise
        ])
        
        return combinedImage
    }
    
    private func applyNegativeFilter(to image: CIImage) -> CIImage {
        // ColorInvert filter for negative film look
        return image.applyingFilter("CIColorInvert")
        
        // Removed the blendImages call that was using intensity
    }
    
    private func applyPositiveFilter(to image: CIImage) -> CIImage {
        // First create a heightened contrast, colorful look
        let vibrant = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 1.2,
            kCIInputContrastKey: 1.1
        ])
        
        // Add a slight vignette
        let vignette = vibrant.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 0.3,
            kCIInputRadiusKey: 1.5
        ])
        
        return vignette
    }
    
    private func applyPolaroidFilter(to image: CIImage) -> CIImage {
        // Create polaroid-like effect: slightly warm, contrast, light vignette, frame
        let base = image.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 6000, y: 0)
        ])
        
        let contrasted = base.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 1.15,
            kCIInputContrastKey: 1.1
        ])
        
        let vignetted = contrasted.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 0.2,
            kCIInputRadiusKey: 1.5
        ])
        
        return vignetted
    }
    
    private func applySepiaFilter(to image: CIImage) -> CIImage {
        return image.applyingFilter("CISepiaTone", parameters: [
            kCIInputIntensityKey: 1.0  // Fixed the missing value
        ])
    }
    
    // Fixed function signature and removed intensity parameter
    private func applyPremiumFilter(to image: CIImage, filter: FilterPreset) -> CIImage {
        // Premium filter implementations
        switch filter.filterType {
        case .cinematic:
            // Cinematic look with blue shadows and amber highlights
            let adjusted = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.8,
                kCIInputContrastKey: 1.2
            ])
            
            let toned = adjusted.applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.2),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.8),
                "inputPoint4": CIVector(x: 1, y: 1)
            ])
            
            let vignetted = toned.applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: 0.4,  // Fixed value without intensity
                kCIInputRadiusKey: 1.0
            ])
            
            return vignetted
            
        case .lomography:
            // High contrast, saturated colors with vignette for lomography look
            let vibrant = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.3,  // Fixed value without intensity
                kCIInputContrastKey: 1.2  // Fixed value without intensity
            ])
            
            let vignetted = vibrant.applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: 0.6,  // Fixed value without intensity
                kCIInputRadiusKey: 0.9
            ])
            
            return vignetted
            
        case .portra400:
            // Kodak Portra 400 inspired - warm, slightly desaturated skin tones
            let warmTones = image.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 5500, y: 0)
            ])
            
            let adjusted = warmTones.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.85,  // Fixed value without intensity
                kCIInputContrastKey: 1.05  // Fixed value without intensity
            ])
            
            return adjusted
            
        case .portra800:
            // Kodak Portra 800 inspired - warmer, slightly more contrast than 400
            let warmTones = image.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 5200, y: 0)
            ])
            
            let adjusted = warmTones.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.9,  // Fixed value without intensity
                kCIInputContrastKey: 1.1  // Fixed value without intensity
            ])
            
            return adjusted
            
        case .kodachrome:
            // Kodachrome inspired - vibrant, strong contrast, slightly warm
            let vibrant = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.2,  // Fixed value without intensity
                kCIInputContrastKey: 1.15  // Fixed value without intensity
            ])
            
            let warmth = vibrant.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 5800, y: 0)
            ])
            
            return warmth
            
        case .ektachrome:
            // Ektachrome inspired - cooler, high contrast
            let vibrant = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.1,  // Fixed value without intensity
                kCIInputContrastKey: 1.2  // Fixed value without intensity
            ])
            
            let coolTones = vibrant.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 7000, y: 0)
            ])
            
            return coolTones
            
        case .fujiSuperior:
            // Fuji Superior inspired - slightly cool, good contrast
            let adjusted = image.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.95,  // Fixed value without intensity
                kCIInputContrastKey: 1.05  // Fixed value without intensity
            ])
            
            let coolTones = adjusted.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: 6700, y: 0)
            ])
            
            return coolTones
            
        case .fujiAcros:
            // Fuji Acros inspired - high contrast B&W with fine grain
            let bw = image.applyingFilter("CIPhotoEffectMono")
            
            let contrasted = bw.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.1  // Fixed value without intensity
            ])
            
            // Add subtle grain (using the fixed function)
            return applyGrainFilter(to: contrasted)
            
        default:
            return image
        }
    }
    
    // Kept this helper function for other parts that might need it
    private func blendImages(image1: CIImage, image2: CIImage, intensity: Double) -> CIImage {
        let blend = CIFilter(name: "CIBlendWithMask")
        blend?.setValue(image1, forKey: kCIInputBackgroundImageKey)
        blend?.setValue(image2, forKey: kCIInputImageKey)
        
        // Create a constant color image for the mask - intensity controls the blend
        let maskImage = CIFilter(name: "CIConstantColorGenerator")
        maskImage?.setValue(CIColor(red: CGFloat(intensity), green: CGFloat(intensity), blue: CGFloat(intensity)), forKey: kCIInputColorKey)
        blend?.setValue(maskImage?.outputImage?.cropped(to: image1.extent), forKey: kCIInputMaskImageKey)
        
        return blend?.outputImage ?? image1
    }
    
    // Save the filtered image to the photo library
    func saveFilteredImage(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let filteredImage = filteredImage else {
            completion(.failure(NSError(domain: "FilmFilter", code: 1, userInfo: [NSLocalizedDescriptionKey: "No filtered image to save"])))
            return
        }
        
        ImageSaver.save(image: filteredImage, completion: completion)
    }
}
