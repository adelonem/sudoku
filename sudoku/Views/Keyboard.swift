//
//  Keyboard.swift
//  sudoku
//

import SwiftUI

struct Keyboard: View {
    let game: Game
    var isPortrait: Bool = false
    @State private var showNewGameConfirmation = false
    @State private var keyboardWidth: CGFloat?
    @State private var rowHeight: CGFloat?
    
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
                lockButton
                noteButton
                eraseButton
                fillNotesButton()
                newGameButton()
            }
        }
    }
    
    // MARK: - Landscape layout (3×3 digit grid + action rows)
    
    private var landscapeLayout: some View {
        VStack(spacing: 4) {
            ForEach(0..<Puzzle.blockSize, id: \.self) { i in
                HStack(spacing: 4) {
                    ForEach(0..<Puzzle.blockSize, id: \.self) { j in
                        let number = Puzzle.blockSize * i + j + 1
                        KeyboardKey(number: number, game: game)
                    }
                }
            }
            
            HStack(spacing: 4) {
                lockButton
                noteButton
                eraseButton
            }
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                keyboardWidth = size.width
                rowHeight = size.height
            }
            
            HStack(spacing: 4) {
                fillNotesButton(square: false)
                newGameButton(square: false)
            }
            .frame(maxWidth: keyboardWidth, maxHeight: rowHeight)
        }
    }
    
    // MARK: - Shared action buttons
    
    private var lockButton: some View {
        KeyboardActionButton(
            icon: game.isLockedMode ? "hand.tap.fill" : "hand.tap",
            isActive: game.isLockedMode,
            tint: .purple
        ) {
            game.toggleLockedMode()
        }
    }
    
    private var noteButton: some View {
        KeyboardActionButton(
            icon: game.isNoteMode ? "pencil.circle.fill" : "pencil.circle",
            isActive: game.isNoteMode,
            tint: .orange
        ) {
            game.toggleNoteMode()
        }
    }
    
    private var eraseButton: some View {
        KeyboardActionButton(
            icon: "delete.backward",
            isActive: game.lockedAction == .erase,
            tint: .red
        ) {
            if game.isLockedMode {
                game.setLockedAction(.erase)
            } else {
                game.deleteCell()
            }
        }
    }
    
    private func fillNotesButton(square: Bool = true) -> some View {
        KeyboardActionButton(
            icon: "wand.and.stars",
            tint: .green,
            square: square
        ) {
            game.fillAllNotes()
        }
    }
    
    private func newGameButton(square: Bool = true) -> some View {
        KeyboardActionButton(
            icon: "arrow.trianglehead.2.counterclockwise",
            tint: .blue,
            square: square
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
