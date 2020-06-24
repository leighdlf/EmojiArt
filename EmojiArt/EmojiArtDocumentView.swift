//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 9/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var chosenPalette: String = ""
    
    init(document: EmojiArtDocument) {
        ///Initialises the View
        self.document = document
        // Sets the state and its wrappedValue for chosenPalette
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack {
                // Passes the document and chosenPalette binding onto the PalletChooser View.
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                
                // Makes a view scrollable.
                ScrollView(.horizontal) {
                    HStack {
                        // Takes a String and casts to an Array of Strings. Needed as ForEach needs Identifiable, and either an array or Int range.
                        // \. is a key path. Specifies a var another object. \ is the object, .self is the var.
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: self.defaultEmojiSize))
                                
                                // onDrag takes a function that returns the things to drag, these things need to be NSItemProvider.
                                // NString is needed, from before Swift.
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                // Sets the palette when the View is loaded.
                // Can be also used to get around init when some vars haven't been set yet.
                // No longer needed as _chosenPalette in init sets it.
                //                    .onAppear { self.chosenPalette = self.document.defaultPalette }
            }
            
            GeometryReader{ geometry in
                // GeometryReader as we use it to set and convert between coordinate systems.
                ZStack {
                    // overlay so we size the image like the rectangle, not its inherent size. .background can also be used.
                    // overlay is a view, not a ViewBuilder. Also look into if you need to do if statements.
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            
                            // Both the zoom and panning are taking into account.
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                    
                    // What is drawn depends on if the background image is loading or not.
                    // Want to give feedback to the user whats going on.
                    if self.isLoading {
                        Image(systemName: "hourglass")
                            .imageScale(.large)
                            .spinning()
                    } else{
                        ForEach(self.document.emojis) { emoji in
                            
                            // Allows for the drawing of the emojis on the document, from the emoji array.
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                                .position(self.position(for: emoji, in: geometry.size))
                        }
                    }
                }
                    // All drawing will be bound to the edges of the view.
                    .clipped()
                    .gesture(self.panGesture())
                    .gesture(self.zoomGesture())
                    
                    // Content is king. Adornments (eg emoji list) are not.
                    .edgesIgnoringSafeArea([.horizontal, .bottom])
                    
                    // Zooms to fit the image to fit whenever the background changes.
                    .onReceive(self.document.$backgroundImage) { image in
                        self.zoomToFit(image, in: geometry.size)
                    }
                    
                    // public.image is a URI, public agreement what is a url? isTargeted is a binding, lets you know when someone is dragging something.
                    // public.text is emoji.
                    // providers NSItemProviders, information on what is being dropped, happens async. More in extensions to help handle.
                    .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                        
                        // location gives global coordinates for some reason, convert in extension converts from global to iOS coordinate system.
                        var location = geometry.convert(location, from: .global)
                        
                        // location here converts from iOS to the offset coordinate system the EmojiArt model uses.
                        location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                        
                        // Adjusts the location from any panning.
                        location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                        
                        // Accounts for zoom scale.
                        location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                        return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(trailing: Button(action: {
                    /// Uses past to ad a background url/image. Needed as iPhones don't have drag.
                    
                    // UIPasteboard.general is the shared pasteboard on the device, returns nil if empty.
                    if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
                        self.confirmBackgroundPast = true
                    } else {
                        self.explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard")
                        .imageScale(.large)
                        
                        // Only one Alert per item.
                        .alert(isPresented: self.$explainBackgroundPaste) { () -> Alert in
                            return Alert(title:
                                Text("Past Background"),
                                         
                                         // Something to be localised.
                                message: Text("Copy the URL of an image to the clipboard and touch this button to make it the background of the document"),
                                
                                // Alert.Button have a lot of stuff on them to choose from.
                                // Don't need closure after to set back to false as it will be done automatically.
                                dismissButton: .default(Text("Ok"))
                            )
                        }
                }))
            }
                // So that the popover isn't is visibal in all zoom levels.
                .zIndex(-1)
        }
            // Asks the user if they want to replace the background with what is shown in the clipboard.
            // Will if they confirm to do so.
            .alert(isPresented: self.$confirmBackgroundPast) {
                return Alert(title:
                    Text("Past Background"),
                             message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                         primaryButton: .default(Text("Ok")) {
                            self.document.backgroundURL = UIPasteboard.general.url
                },
                secondaryButton: .cancel()
            )
        }
        
    }
    
    // To see if alert is showing.
    @State private var explainBackgroundPaste = false
    
    //
    @State private var confirmBackgroundPast = false
    
   
    
    // MARK: - Gestures.
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        /// Resizes the background image on a double tap.
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
        }
            // Makes sure the double tap is recognised before the single tap.
            .exclusively(before: TapGesture(count: 1))
    }
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        /// Adjusts based on pinch zoom scale occurring during the gesture.
        self.document.steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        /// Implements a zoomGesture. .onEnd sets the new zoom level after the gesture is complete.
        
        // This func essentially owns the gesture state. This should be the only place it should be modified; never assign a value directly.
        MagnificationGesture()
            
            // .updating is constantly being called thorough the gesture.
            // latestGestureScale is what the latest gesture values looks like.
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transition in
                
                // Normal name of param is ourGestureStateInOut, rename to input to make more explicit.
                // Sets the gestureZoomScale to whatever the latestGestureScale is during the gesture.
                gestureZoomScale = latestGestureScale
        }
            // finalGestureScale The gesture scale at the end when the users fingers lift off the screen.
            .onEnded { finalGestureScale in
                
                // Sets a new value for the steadyStateZoomScale to the scale after the gesture is complete.
                self.document.steadyStateZoomScale *= finalGestureScale
        }
    }
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        /// Sets the pan offset.
        
        // Similar to zoomScale
        // Normally can't add points like this but added the ability in extensions.
        (self.document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        /// Pans around the document.
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                
                // translation is the difference in position between the end and start position (using x and y values)
                // zoomScale need to be taken into account.
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
            // latestDragGestureValue is more complex than latestGestureScale in zoomGesture, it's a struct. Look at docs.
            .onEnded { finalDragGestureValue in
                self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }
    
    
    // MARK: - Other functions?
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        /// Resizes the background image by the smallest of either its width or height.
        
        // size.height > 0, size.width > 0 is to make sure the zoom scale is never set to zero. Needed as bug fix.
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            
            // Resets to the centre after doubleTapToZoom has occurred.
            self.document.steadyStatePanOffset = .zero
            
            // Uses the smallest value so the entire image will always fit the screen.
            self.document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        /// Positions the Emoji on the document.
        
        var location = emoji.location
        
        // Account for zoomScale when positioning.
        location = CGPoint(x: location.x * self.zoomScale, y: location.y * self.zoomScale)
        
        // Converts position from offset to iOS coordinate system
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
        
        // Taking into account any panning that occurred.
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        /// Returns true if the drop succeeded and adds the item to the document.
        
        // URL.self means the type URL, returns the var with the type. loadFirstObject is in extensions.
        // providers is the array of NSItemProvider
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.backgroundURL = url
        }
        if !found {
            // If its not a URL passed but we are now loading up all String. Allows for the dragging of emojis.
            found = providers.loadFirstObject(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    var isLoading: Bool {
        /// Is the background image loading or not.
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    private let defaultEmojiSize: CGFloat = 40
}



//extension String: Identifiable {
//    /// Extension to make strings identifiable. Takes the String and uses it to make the id. Stings are equatable.
//    /// Public is to make it non-private in a library.
//    /// Don't want to do this!
//    public var id: String { return self }
//}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmojiArtDocumentView()
//    }
//}
