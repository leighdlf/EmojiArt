//
//  EmojiArtDocumentStore.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 5/6/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine

// A second View Model.
class EmojiArtDocumentStore: ObservableObject
{
    let name: String
    
    // EmojiArtDocument means this is a View Model with other View Models within it?
    func name(for document: EmojiArtDocument) -> String {
        if documentNames[document] == nil {
            documentNames[document] = "Untitled"
        }
        return documentNames[document]!
    }
    
    /// Sets a documents name.
    func setName(_ name: String, for document: EmojiArtDocument) {
        if let url = directory?.appendingPathComponent(name) {
            
            if !documentNames.values.contains(name) {
                
                // removes in the case of renaming, not setting a new name.
                removeDocument(document)
                document.url = url
                documentNames[document] = name
            } else {
                // if the name is already present it won't allow renaming.. Could enhance in a real production app. Alert?
                documentNames[document] = name
            }
        }
        documentNames[document] = name
    }
    
    var documents: [EmojiArtDocument] {
        documentNames.keys.sorted { documentNames[$0]! < documentNames[$1]! }
    }
    
    /// Adds a new document.
    func addDocument(named name: String = "Untitled") {
        
        // Each document in the filesystem needs a unique name.
        // Creates a unique name if the past in names is already in use. uniqued(withRespectTo:) is in extensions.
        // documentNames.values returns a Collection, not an array.
        let uniqueName = name.uniqued(withRespectTo: documentNames.values)
        
        let document: EmojiArtDocument
        
        // Create a url for the document. if let as the document could be nit, someone used init(named:), not init(document:)
        // Creates an empty on if so.
        if let url = directory?.appendingPathComponent(uniqueName) {
            document = EmojiArtDocument(url: url)
        } else {
            document = EmojiArtDocument()
        }
        documentNames[document] = uniqueName
    }

    /// Removes documents.
    func removeDocument(_ document: EmojiArtDocument) {
        if let name = documentNames[document], let url = directory?.appendingPathComponent(name) {
            
            // try? as if we can't remove what is there to do? Report the errors to see if they're recoverable? Unlikely.
            try? FileManager.default.removeItem(at: url)
        }
        documentNames[document] = nil
    }
    
    // A dictionary with EmojiArtDocuments as keys, and Strings as the values/names.
    // The entirety of the storage of this View Model.
    // Common to have View Models that are essentially stores for things.
    // Not really logic oriented.
    @Published private var documentNames = [EmojiArtDocument:String]()
    
    private var autosave: AnyCancellable?
    
    init(named name: String = "Emoji Art") {
        self.name = name
        let defaultsKey = "EmojiArtDocumentStore.\(name)"
        documentNames = Dictionary(fromPropertyList: UserDefaults.standard.object(forKey: defaultsKey))
        // Using combine to autosave.
        autosave = $documentNames.sink { names in
            UserDefaults.standard.set(names.asPropertyList, forKey: defaultsKey)
        }
    }
    
    
    private var directory: URL?
    /// Alternate init for interacting with the filesystem, not UserDefaults.
    /// - Parameter directory: url of the document store. In reality we would also want another arg for the name.
    init(directory: URL) {
        
        // directory.lastPathComponent might not be good as it might be some internal naming convention?
        self.name = directory.lastPathComponent
        self.directory = directory
        // do/catch instead of try? Don't need to always use try?
        do {
            // Opens and reads the documents in the supplied directory.
            // path is a url var that is a string. It will be the names of all the fils in the directory.
            let documents = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            for document in documents {
                
                // appendingPathComponent(document) will create a url from the name for each document in the documents directory.
                let emojiArtDocument = EmojiArtDocument(url: directory.appendingPathComponent(document))
                
                // Updates the store/data structure to whats in the filesystem.
                self.documentNames[emojiArtDocument] = document
            }
        } catch {
            // Could try to recover as much as possible. Let the user know whats happening.
            print("EmojiArt store couldn't create store from directory \(directory) - \(error.localizedDescription)")
        }
    }
}

extension Dictionary where Key == EmojiArtDocument, Value == String {
    /// Converts a dictionary to a property list.
    // This is required to store in UserDefaults.
    // Look at this as it's cool.
    var asPropertyList: [String:String] {
        var uuidToName = [String:String]()
        for (key, value) in self {
            uuidToName[key.id.uuidString] = value
        }
        return uuidToName
    }
    
    init(fromPropertyList plist: Any?) {
        /// Creates from a property list.
        // as? and Any? as UserDefaults are old APIs.
        self.init()
        let uuidToName = plist as? [String:String] ?? [:]
        for uuid in uuidToName.keys {
            self[EmojiArtDocument(id: UUID(uuidString: uuid))] = uuidToName[uuid]
        }
    }
}
