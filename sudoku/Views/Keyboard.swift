//
//  Keyboard.swift
//  sudoku
//

import SwiftUI

struct Keyboard: View {
    @Environment(Game.self) private var game
    var isPortrait: Bool = false
    @State private var showNewGameConfirmation = false
    @State private var showPuzzleNumberInput = false
    
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
                        KeyboardKey(number: number)
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
                        KeyboardKey(number: number)
                    }
                }
            }
            
            HStack(spacing: 4) {
                lockButton
                noteButton
                eraseButton
            }
            
            HStack(spacing: 4) {
                fillNotesButton(aspectRatio: 1.5)
                newGameButton(aspectRatio: 1.5)
            }
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
    
    private func fillNotesButton(aspectRatio: CGFloat = 1.0) -> some View {
        KeyboardActionButton(
            icon: "wand.and.stars",
            tint: .green,
            aspectRatio: aspectRatio
        ) {
            game.fillAllNotes()
        }
    }
    
    private func newGameButton(aspectRatio: CGFloat = 1.0) -> some View {
        KeyboardActionButton(
            icon: "arrow.trianglehead.2.counterclockwise",
            tint: .blue,
            aspectRatio: aspectRatio
        ) {
            showNewGameConfirmation = true
        }
        .confirmationDialog("Start a New Game?", isPresented: $showNewGameConfirmation, titleVisibility: .visible) {
            Button("Random Puzzle") {
                game.newGame()
            }
            Button("Choose Puzzle\u{2026}") {
                showPuzzleNumberInput = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current progress will be lost.")
        }
        .puzzleNumberPicker(isPresented: $showPuzzleNumberInput)
    }
}
