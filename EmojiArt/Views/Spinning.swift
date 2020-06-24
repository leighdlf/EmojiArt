//
//  Spinning.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 16/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

import SwiftUI

struct Spinning: ViewModifier {
    /// View Modifier that gives the view a spinning rotation animation.
    
    @State var isVisible: Bool = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isVisible ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear { self.isVisible = true }
    }
}

extension View {
    func spinning() -> some View {
        self.modifier(Spinning())
    }
}
