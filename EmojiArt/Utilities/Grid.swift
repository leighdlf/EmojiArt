//
//  Grid.swift
//  Memorise
//
//  Created by Leigh De La Fontaine on 2/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

// Can be used in all apps that need a grid.
// @escaping if for items not used/assigned now but later. Needs to be around for the future. Function types now references types. Lives/makes sure its in the heap?

import SwiftUI

extension Grid where Item: Identifiable, ID == Item.ID {
    /// Extension to Grid where Item: Identifiable, ID == Item.ID only
    // Item.ID is the don't care for Identifiable, ID is the don't care for Grid.
    // Forcing that they both are the same so we can call the init like we used to.
    
    init(_ items: [Item], viewForItem: @escaping (Item) -> ItemView) {
        self.init(items, id: \Item.id, viewForItem: viewForItem)
    }
}

 // Care a little bit. Protocols so generics can work, connect them.
// ID requiring to be Hashable is required.
struct Grid<Item, ID, ItemView>: View where ID: Hashable, ItemView: View {
    private var items: [Item]
    private var id: KeyPath<Item, ID>
    private var viewForItem: (Item) -> ItemView
    
    // Added keyPath. first arg is that are don't care, first Item are things in the array, ID is return type that we don't care about.
    init(_ items: [Item], id: KeyPath<Item, ID>, viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.id = id
        self.viewForItem = viewForItem
    }
    
    // How much space given to the grid. Divides up space to its children. How much space is given to.
    var body: some View {
        GeometryReader { geometry in
            self.body(for: GridLayout(itemCount: self.items.count, in: geometry.size))
        }
    }
    
    // Divide the space given amongst the child elements
    // Trick to overcome self. in geometry reader. Just pass geometry.size not whole body. Same is in EmojiMemoryGameView.
    private func body(for layout: GridLayout) -> some View {
        
        // ForEach is sort of creating a dictionary? Why things need to be hashable.
        ForEach(items, id: id) { item in
            self.body(for: item, in: layout)
        }
    }
    
    // Offer the space the the children. Then position them in the grid layout.
    private func body(for item: Item, in layout: GridLayout) -> some View {
        // Gets the keyPath for the get the keyPath var from the item and return it. Then compares to $0 keyPath id.
        let index = items.firstIndex(where: { item[keyPath: id] == $0[keyPath: id] } )
        return Group {
            if index != nil {
                viewForItem(item)
                    .frame(width: layout.itemSize.width, height: layout.itemSize.height)
                    .position(layout.location(ofItemAt: index!))
            }
        }
    }
}


