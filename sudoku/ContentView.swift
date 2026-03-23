//
//  ContentView.swift
//  sudoku
//

import SwiftUI

struct ContentView: View {
    @State private var game = Game()
    
    var body: some View {
        HStack(alignment: .bottom) {
            PuzzleGrid(game: game)
                .layoutPriority(1)
            
            VStack(spacing: 8) {
                if let number = game.puzzleNumber {
                    Text("Puzzle #\(number)")
                        .font(.headline)
                }
                if let difficulty = game.puzzleDifficulty {
                    Text(difficulty.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Keyboard(game: game)
            }
        }
        .overlay(alignment: .top) {
            if game.isLoading || game.isSaving {
                ProgressView()
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity)
            }
        }
        .animation(.default, value: game.isLoading)
        .animation(.default, value: game.isSaving)
        .onAppear {
            game.load()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
