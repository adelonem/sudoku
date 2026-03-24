//
//  Keyboard.swift
//  sudoku
//

import SwiftUI

struct Keyboard: View {
    let game: Game
    @State private var showNewGameConfirmation = false
    
    var body: some View {
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
                KeyboardActionButton(
                    icon: "wand.and.stars",
                    tint: .green
                ) {
                    game.fillAllNotes()
                }
                
                Button {
                    showNewGameConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(2.0, contentMode: .fit)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .gridCellColumns(Puzzle.blockSize - 1)
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
}
