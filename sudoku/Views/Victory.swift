//
//  Victory.swift
//  sudoku
//

import SwiftUI

struct Victory: View {
    let game: Game
    
    @State private var showPuzzleNumberInput = false
    @State private var puzzleNumberText = ""
    @State private var showInvalidPuzzleAlert = false
    
    private static let backgroundColor: Color = .platformBackground
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            
            Text("Congratulations!")
                .font(.largeTitle.bold())
            
            Text("You successfully solved the puzzle.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button {
                    game.newGame()
                } label: {
                    Label("Random Puzzle", systemImage: "arrow.trianglehead.2.counterclockwise")
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    puzzleNumberText = ""
                    showPuzzleNumberInput = true
                } label: {
                    Label("Choose Puzzle…", systemImage: "number")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .background(Self.backgroundColor, in: RoundedRectangle(cornerRadius: 20))
        .alert("Choose a Puzzle", isPresented: $showPuzzleNumberInput) {
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
            Text("Enter a puzzle number between 1 and \(game.puzzleCount).")
        }
        .alert("Puzzle Not Found", isPresented: $showInvalidPuzzleAlert) {
            Button("OK") {}
        } message: {
            Text("No puzzle matches this number. Please choose a number between 1 and \(game.puzzleCount).")
        }
    }
}
