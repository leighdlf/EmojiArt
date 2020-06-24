//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 9/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//


import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    /// View Model for a single EmojiArt document
    
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        /// Required to be Equatable.
        // This would only work for references types, not value types.
        // Hashable in structs hash all the vars.
        lhs.id == rhs.id
    }
    
    // This allows the document to be both Hashable and Identifiable.
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        /// This func is required to conform to Hashable.
        
        // Combining multiple things to make them Hashable? UUID used here to create a unique thing.
        hasher.combine(id)
    }
    
    // ObservableObject to facilitate reactive UI.
    // Static as it's not tied to an instance of EmojiArtDocument.
    // The default palette.
    static let palette: String = "⭐️⛈🍎🌏🥨⚾️"
    
    // A link to the model. Publishes when changes occur. @Published have Error as Never.
    
    @Published private var emojiArt: EmojiArt
    
    // Publishes when the background image changes.
    @Published private(set) var backgroundImage: UIImage?
    
    // Added to the View Model from the View so they are preserved when going between documents.
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    
    
    // AnyCancellable is a type erased version of cancellable in init().
    private var autosaveCancellable: AnyCancellable?
    
    init(id: UUID? = nil) {
        /// Initialises EmojiArtDocument
        // Will create a blank document if EmojiArt init fails/returns nil
        
        // This gives flexibility. Keeps whatever id defaults it too internal; don't want it visible externally.
        self.id = id ?? UUID()
        
        // sets the defaultsKey.
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        
        // Also will fetch the background image.
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        
        // Never want the result os .sink to go unused!
        // .sink subscribes to what tis bound to.
        // let autosaveCancellable makes sure this subscription never ends?
        autosaveCancellable = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
        fetchBackgroundImageData()
    }
    
    // didSet to immediately save emojiArt to a new url incase the url changes. To be safe.
    // Most likely if someone sets a new url they want it autsaved quickly?
    var url: URL? { didSet { self.save(self.emojiArt) } }
    
    /// Stores the EmojiArtDocument in the filesystem instead of UserDefaults, like the other init.
    /// - Parameter url: Url for the location in the filesystem. Stored in the above var url.
    init(url: URL) {
        self.id = UUID()
        self.url = url
        
        // Loading of the EmojiArtDocument. Trys to red the contents of the url, if it fails it creates an empty document.
        self.emojiArt = EmojiArt(json: try? Data(contentsOf: url)) ?? EmojiArt()
        fetchBackgroundImageData()
        autosaveCancellable = $emojiArt.sink(receiveValue: { emojiArt in
            self.save(emojiArt)
        })
    }
    
    /// Saves an EmojiArt
    /// - Parameter emojiArt: The EmojiArt to save.
    private func save(_ emojiArt: EmojiArt) {
        if url != nil {
            try? emojiArt.json?.write(to: url!)
        }
    }
    
    // A computed/read only version of the EmojiArts as an array.
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    // A set of selected emojis in the document.
//    var selectedEmojis: Set<EmojiArt.Emoji> = []
    
    // MARK: - Intent(s)
    // Interfaces between the views and the model.
    // Converts the CG values into Ints that the model expects.
    // firstIndex is defunded in extensions. Used so we can change the matching Emoji in the array.
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        // Adds an emoji from the palette onto the document.
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
//    func selectEmoji(_ emoji: EmojiArt.Emoji) {
//        /// Selects an emoji on the document and adds it to a set of all selected emojis. For A4-Q2.
//        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
//            self.selectedEmojis.insert(emojiArt.emojis[index])
//        }
//    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }

    var backgroundURL: URL? {
        /// Gets and sets the background URL/Image.
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    
    // So that the publisher in fetchBackgroundImageData never goes away.
    // Also allows for it to be canceled and not having outstanding requests. fetchedImageCancellable?.cancel() does this.
    private var fetchedImageCancellable: AnyCancellable?
    
    private func fetchBackgroundImageData() {
        /// Sets the backgroundImage
        // sets to nil to give feedback to the user that a new image is being fetched/set. This might take time.
        backgroundImage = nil
        // if let so it only does something if it's not nil; actually contains something.
        if let url = self.emojiArt.backgroundURL {
            
            // Cancels the current subscription.
            fetchedImageCancellable?.cancel()
            
            // Ask URLSession to go fetch data.
            // .shared is a static var that the whole app can use when doing simple downloads.
            // Does its work in a background queue.
            fetchedImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                
                // maps the data and URL response in the url and maps it to the data we want; an optional URImage.
                .map { data, urlResponse in UIImage(data: data) }
                
                // Then a new publisher dispatches this on the main queue. Takes a publisher and modifies it.
                .receive(on: DispatchQueue.main)
                
                // Changes its error type to Never.
                .replaceError(with: nil)
                
                // .assign assigns the output of a publisher to a var, by keyPath and object with the same type as the published data.
                // .assign only works when error is Never.
                .assign(to: \.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    // Doesn't violate MVVM as its in the VM, not view. View never has to deal with Ints.
    // Converts from the Int used in the model to CG units that the view uses.
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

