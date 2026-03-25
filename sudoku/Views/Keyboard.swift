//
//  Keyboard.swift
//  sudoku
//

import SwiftUI

struct Keyboard: View {
    let game: Game
    var isPortrait: Bool = false
    @State private var showNewGameConfirmation = false
    
    var body: some View {
        if isPortrait {
            portraitLayout
        } else {
            landscapeLayout
        }
    }
    
    // MARK: - Portrait layout (1 row of digits + action row)
    
    private var portraitLayout: some View {
        VStack(spacing: 4) {
            Grid(horizontalSpacing: 4, verticalSpacing: 0) {
                GridRow {
                    ForEach(1...9, id: \.self) { number in
                        KeyboardKey(number: number, game: game)
                    }
                }
            }
            
            HStack(spacing: 4) {
                KeyboardActionButton(
                    icon: game.isLockedMode ? "hand.tap.fill" : "hand.tap",
                    isActive: game.isLockedMode,
                    tint: .purple
                ) {
                    game.toggleLockedAction()
                }
                
                KeyboardActionButton(
                    icon: game.isNoteMode ? "pencil.circle.fill" : "pencil.circle",
                    isActive: game.isNoteMode,
                    tint: .orange
                ) {
                    game.toggleNoteMode()
                }
                
                KeyboardActionButton(
                    icon: "delete.backward",
                    isActive: game.lockedAction == .erase,
                    tint: .red
                ) {
                    if game.isLockedMode {
                        game.toggleLockedAction(.erase)
                    } else {
                        game.deleteCell()
                    }
                }
                
                KeyboardActionButton(
                    icon: "wand.and.stars",
                    tint: .green
                ) {
                    game.fillAllNotes()
                }
                
                KeyboardActionButton(
                    icon: "arrow.counterclockwise",
                    tint: .blue
                ) {
                    showNewGameConfirmation = true
                }
                .confirmationDialog("Start a new game?", isPresented: $showNewGameConfirmation, titleVisibility: .visible) {
                    Button("New Game") {
                        game.newGame()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Your current progress will be lost.")
                }
            }
        }
    }
    
    // MARK: - Landscape layout (3×3 digit grid + action rows)
    
    private var landscapeLayout: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<Puzzle.blockSize, id: \.self) { i in
                GridRow {
                    ForEach(0..<Puzzle.blockSize, id: \.self) { j in
                        let number = Puzzle.blockSize * i + j + 1
                        KeyboardKey(number: number, game: game)
                    }
                }
            }
            
            GridRow {
                KeyboardActionButton(
                    icon: game.isLockedMode ? "hand.tap.fill" : "hand.tap",
                    isActive: game.isLockedMode,
                    tint: .purple
                ) {
                    game.toggleLockedAction()
                }
                
                KeyboardActionButton(
                    icon: game.isNoteMode ? "pencil.circle.fill" : "pencil.circle",
                    isActive: game.isNoteMode,
                    tint: .orange
                ) {
                    game.toggleNoteMode()
                }
                
                KeyboardActionButton(
                    icon: "delete.backward",
                    isActive: game.lockedAction == .erase,
                    tint: .red
                ) {
                    if game.isLockedMode {
                        game.toggleLockedAction(.erase)
                    } else {
                        game.deleteCell()
                    }
                }
            }
            
            GridRow {
                HStack(spacing: 4) {
                    KeyboardActionButton(
                        icon: "wand.and.stars",
                        tint: .green,
                        square: false
                    ) {
                        game.fillAllNotes()
                    }
                    
                    KeyboardActionButton(
                        icon: "arrow.counterclockwise",
                        tint: .blue,
                        square: false
                    ) {
                        showNewGameConfirmation = true
                    }
                    .confirmationDialog("Start a new game?", isPresented: $showNewGameConfirmation, titleVisibility: .visible) {
                        Button("New Game") {
                            game.newGame()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Your current progress will be lost.")
                    }
                }
                .gridCellColumns(Puzzle.blockSize)
            }
        }
    }
}
