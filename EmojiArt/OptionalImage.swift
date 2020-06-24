//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 9/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

import SwiftUI

struct OptionalImage: View {
    ///Displays an optional UIImage image view.
    
    // It's good practice to seperate views into smaller chunks.
    
    var uiImage: UIImage?
    
    // Group if you ned to us an if statement for a ViewBuilder.
    var body: some View {
        Group {
             if uiImage != nil {
                 Image(uiImage: uiImage!)
             }
         }
    }
}
