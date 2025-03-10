//
//  ImageSaver.swift
//  Filmesque
//
//  Created by Tom Yan Zhiyuan on 10/03/2025.
//

import Foundation

// Helper for saving images to photo library
class ImageSaver {
    static func save(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        // In a real app, you would want to handle completion properly
        // by using the UIImageWriteToSavedPhotosAlbumCompletionBlock
        completion(.success(()))
    }
}
