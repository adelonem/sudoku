//
//  PuzzleNumberPicker.swift
//  sudoku
//

import SwiftUI

/// A reusable modifier that presents the "choose a puzzle by number" alert flow.
struct PuzzleNumberPicker: ViewModifier {
    @Environment(Game.self) private var game
    @Binding var isPresented: Bool
    
    @State private var puzzleNumberText = ""
    @State private var showInvalidPuzzleAlert = false
    
    func body(content: Content) -> some View {
        content
            .alert("Choose a Puzzle", isPresented: $isPresented) {
                TextField("Puzzle number", text: $puzzleNumberText)
#if !os(macOS)
                    .keyboardType(.numberPad)
#endif
                Button("Start") {
                    if let number = Int(puzzleNumberText),
                       game.newGame(number: number) {
                        // Success – game loaded
                    } else {
                        showInvalidPuzzleAlert = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a puzzle number between 1 and \(Storage.puzzleCount).")
            }
            .alert("Puzzle Not Found", isPresented: $showInvalidPuzzleAlert) {
                Button("OK") {}
            } message: {
                Text("No puzzle matches this number. Please choose a number between 1 and \(Storage.puzzleCount).")
            }
            .onChange(of: isPresented) { _, newValue in
                if newValue { puzzleNumberText = "" }
            }
    }
}

extension View {
    func puzzleNumberPicker(isPresented: Binding<Bool>) -> some View {
        modifier(PuzzleNumberPicker(isPresented: isPresented))
    }
}
