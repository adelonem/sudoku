//
//  Victory.swift
//  sudoku
//

import SwiftUI

struct Victory: View {
    @Environment(Game.self) private var game
    @State private var showPuzzleNumberInput = false
    
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
                    showPuzzleNumberInput = true
                } label: {
                    Label("Choose Puzzle\u{2026}", systemImage: "number")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .background(Style.background, in: RoundedRectangle(cornerRadius: Style.victoryCornerRadius))
        .puzzleNumberPicker(isPresented: $showPuzzleNumberInput)
    }
}
