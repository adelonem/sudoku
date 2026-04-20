//
//  KeyboardView.swift
//  Sudoku
//

import SwiftUI

struct KeyboardView: View {
    var viewModel: PuzzleViewModel
    var isPortrait: Bool = false
    @State private var showRestartConfirmation = false
    
    var body: some View {
        if isPortrait {
            portraitLayout
        } else {
            landscapeLayout
        }
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 10) {
            portraitActionRow
            Grid(horizontalSpacing: 4, verticalSpacing: 0) {
                GridRow {
                    ForEach(1...Puzzle.size, id: \.self) { number in
                        KeyboardKeyView(number: number, aspectRatio: 1.5, viewModel: viewModel)
                    }
                }
            }
        }
    }
    
    private var landscapeLayout: some View {
        VStack(spacing: 4) {
            landscapeActionRow
            ForEach(0..<Puzzle.blockSize, id: \.self) { i in
                HStack(spacing: 4) {
                    ForEach(0..<Puzzle.blockSize, id: \.self) { j in
                        KeyboardKeyView(number: Puzzle.blockSize * i + j + 1, viewModel: viewModel)
                    }
                }
            }
        }
    }
    
    private var hintButton: some View {
        KeyboardActionButtonView(
            icon: viewModel.isShowingHint ? "lightbulb.max.fill" : "lightbulb.fill",
            accessibilityLabel: viewModel.isShowingHint ? "Hide Hint" : "Show Hint",
            isActive: viewModel.isShowingHint
        ) {
            viewModel.requestHint()
        }
    }
    
    private var fillNotesButton: some View {
        KeyboardActionButtonView(
            icon: "wand.and.stars",
            accessibilityLabel: viewModel.showPossibilities ? "Hide Candidates" : "Show Candidates",
            isActive: viewModel.showPossibilities
        ) {
            viewModel.togglePossibilities()
        }
    }
    
    private var newGameButton: some View {
        KeyboardActionButtonView(
            icon: "arrow.trianglehead.counterclockwise",
            accessibilityLabel: "Restart Puzzle"
        ) {
            showRestartConfirmation = true
        }
        .confirmationDialog("Restart Puzzle?", isPresented: $showRestartConfirmation, titleVisibility: .visible) {
            Button("Restart") {
                viewModel.restartGame()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current progress will be lost.")
        }
    }
    
    private var portraitActionRow: some View {
        HStack(spacing: 4) {
            fillNotesButton
            hintButton
            newGameButton
        }
    }
    
    private var landscapeActionRow: some View {
        HStack(spacing: 4) {
            fillNotesButton
            hintButton
            newGameButton
        }
    }
}

#Preview("Portrait") {
    KeyboardView(viewModel: PuzzleViewModel(puzzle: .sample), isPortrait: true)
        .padding()
}

#Preview("Landscape") {
    KeyboardView(viewModel: PuzzleViewModel(puzzle: .sample))
        .padding()
}
