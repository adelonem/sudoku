//
//  Header.swift
//  sudoku
//

import SwiftUI

struct Header: View {
    let game: Game
    
    var body: some View {
        HStack {
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
            
            Spacer()
            
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
    }
}
