//
//  ImagePicker.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 25/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

import SwiftUI
import UIKit

// Privacy - Camera Usage Description needs to be set in the info.plist to have ask for access to the camera.

// typealias useful when using complex types throughout a project.
typealias PickedImageHandler = (UIImage?) -> Void

// More info in the Enroute, as it was done first.
struct ImagePicker: UIViewControllerRepresentable {
    
    // Allows for the selection from both the image library of the camera.
    var sourceType: UIImagePickerController.SourceType
    
    // An alternative method than using @Binding
    // Is a closure that will be called when you pick an image.
    var handlePickedImage: PickedImageHandler
    

    
    // Allows for the selection of photos from the users photo library or camera
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Allows for the selection from both the image library of the camera.
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    // Makes the delegate
    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage)
    }
    
    // The delegate
    // UINavigationControllerDelegate is required for UIImagePickerController
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var handlePickedImage: PickedImageHandler
        
        // @escaping as we take the func in and hold on to it.
        init(handlePickedImage: @escaping PickedImageHandler) {
            self.handlePickedImage = handlePickedImage
        }
        
        // When the user selects the image.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            // getting the image from the UIImagePickerController dictionary. Have to cast as its from Objective C, will return nil if it fails.
            handlePickedImage(info[.originalImage] as? UIImage)
        }
        
        // when the user cancels the controller.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            handlePickedImage(nil)
        }
    }
}
