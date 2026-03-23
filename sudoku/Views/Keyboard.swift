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
                        KeyboardDigitKey(number: number, game: game)
                    }
                }
            }
            
            GridRow {
                KeyboardActionButton(
                    icon: game.digitFirstDigit != nil ? "hand.tap.fill" : "hand.tap",
                    isActive: game.digitFirstDigit != nil,
                    tint: .purple
                ) {
                    game.toggleDigitFirst(1)
                }
                
                KeyboardActionButton(
                    icon: game.isNoteMode ? "pencil.circle.fill" : "pencil.circle",
                    isActive: game.isNoteMode,
                    tint: .orange
                ) {
                    game.toggleNoteMode()
                }
                
                KeyboardActionButton(
                    icon: "wand.and.stars",
                    tint: .green
                ) {
                    game.fillAllNotes()
                }
            }
            
            GridRow {
                Button {
                    showNewGameConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(3.0, contentMode: .fit)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .gridCellColumns(Puzzle.blockSize)
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
