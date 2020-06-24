//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 17/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    /// View for the EmojiArtDocumentStore.
    
    // Store is an EnvironmentObject to mix it up, it's common to use in a top level view.
    @EnvironmentObject var store: EmojiArtDocumentStore
    
    // Sets the EditMode in the environment.
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        
        // NavigationView is generally for Lists, though others such as Forms can be used also.
        NavigationView {
            // Similar to a tableview from UIKit.
            List {
                // Making the view models identifiable allows us to use ForEach!
                ForEach(store.documents) { document in
                    
                    // Links to a EmojiArtDocumentView that shows that document.
                    NavigationLink(destination: EmojiArtDocumentView(document: document)
                        
                        // Put the title on the linked view that will be shown.
                        .navigationBarTitle(self.store.name(for: document))
                    ) {
                        // Look into Utils to see what this does.
                        // Allows to nicely switch out when in editing mode or not.
                        EditableText(self.store.name(for: document), isEditing: self.editMode.isEditing) { name in
                            self.store.setName(name, for: document)
                        }
                    }
                }
                    // For all things in the indexSet remove that document.
                    // maps the index to the documents.
                    .onDelete { (IndexSet) in
                        IndexSet.map { self.store.documents[$0] }.forEach { (document) in
                            self.store.removeDocument(document)
                        }
                }
            }
            .navigationBarTitle(self.store.name)
            .navigationBarItems(
                
                // Adds a new untitled document.
                leading: Button(action: {
                    self.store.addDocument()
                }, label: {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }),
                // EditButton is a SwiftUI struct.
                // It has an optional binding to editMode in the environment. Has a get and set.
                trailing: EditButton()
            )
                // Allows for the change of environment values by a key value pair.
                // Only for the view that it's called on and the view needs to have the edit button. So it's outside the ForEach??
                .environment(\.editMode, $editMode)
        }
    }
}


struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
