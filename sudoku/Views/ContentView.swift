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
                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let number = game.puzzleNumber {
                            Text("Puzzle #\(number)")
                                .font(.headline)
                        }
                        if let difficulty = game.puzzleDifficulty {
                            Text(difficulty.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        game.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.title)
                            .foregroundStyle(game.canUndo ? .blue : .gray.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .disabled(!game.canUndo)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if game.isSolved {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                Victory {
                    game.newGame()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.5), value: game.isSolved)
        .onAppear {
            game.load()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
