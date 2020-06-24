//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Leigh De La Fontaine on 16/6/20.
//  Copyright © 2020 Leigh De La Fontaine. All rights reserved.
//

import SwiftUI

struct PaletteChooser: View {
    /// Lets user choose the palette.
    
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var chosenPalette: String
    @State private var showPaletteEditor = false
    
    var body: some View {
        HStack {
            Stepper(onIncrement: {
                self.chosenPalette = self.document.palette(after: self.chosenPalette)
            }, onDecrement: {
                self.chosenPalette = self.document.palette(after: self.chosenPalette)
            }, label: {
                // Label should explain what the Stepper does.
                EmptyView()
            })
            Text(document.paletteNames[self.chosenPalette] ?? "")
            Image(systemName: "keyboard")
                .imageScale(.large)
                .onTapGesture {
                    self.showPaletteEditor = true
            }
                // .popover only really an iPad thing, different on iPhone.
                // Can give args for arrow direction?
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(chosenPalette: self.$chosenPalette, isShowing: self.$showPaletteEditor)
                        
                        // Passes on the environment object
                        .environmentObject(self.document)
                        .frame(minWidth: 300, minHeight: 500)
            }
        }
            // Only use space needed and not any extra offered to it.
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    /// Popover palette editor
    
    @EnvironmentObject var document: EmojiArtDocument
    
    // Binding of a binding.
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("PaletteEditor")
                    .font(.headline)
                    .padding()
                HStack {
                    Spacer()
                    
                    // Dismisses the sheet.
                    Button(action: {
                        self.isShowing = false
                    }, label: { Text("Done") })
                        .padding()
                }
            }
            
            Divider()
            
            Form {
                Section {
                    // In iOS we try not to have extraneous labels
                    // Binding is what is being edited.
                    TextField("Palette Name", text: $paletteName, onEditingChanged:  { began in
                        // can be began or ended
                        // Changes palette name when editing is complete.
                        if !began {
                            // Adds new emojis to the palette.
                            self.document.renamePalette(self.chosenPalette, to: self.paletteName)
                        }
                    })
                        .padding()
                    
                    TextField("Add Emojis", text: $emojisToAdd, onEditingChanged:  { began in
                        // can be began or ended
                        // Changes palette name when editing is complete.
                        if !began {
                            self.chosenPalette = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPalette)
                            
                            // resets emojis to add after adding them.
                            self.emojisToAdd = ""
                        }
                    } )
                        .padding()
                }
                
                Section(header: Text("Remove Emoji")) {
                    /// Removes selected emoji from the palette
                    VStack {
                        // Grid from Memorize.
                        Grid(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.fontSize))
                                .onTapGesture {
                                    self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: self.chosenPalette)
                            }
                        }
                            // Gives more space for grid.
                        .frame(height: self.height)
                    }
                }
            }
            
        }
            // Sets the palette name to that of the chosen palette when the view appears.
        .onAppear { self.paletteName = self.document.paletteNames[self.chosenPalette] ?? "" }
    }
    
    var height: CGFloat {
        // Calculated to make the emoji fit well in the space.
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
