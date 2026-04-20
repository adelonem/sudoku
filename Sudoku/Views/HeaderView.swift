//
//  HeaderView.swift
//  Sudoku
//

import SwiftUI

struct HeaderView: View {
    var viewModel: PuzzleViewModel
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    @State private var showTechniques = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let number = viewModel.puzzleNumber {
                    Text("Puzzle #\(number)")
                        .font(fontOption.font(for: .headline))
                }
                if let difficulty = viewModel.puzzleDifficulty {
                    HStack(spacing: 4) {
                        Text(localizedDifficulty(difficulty))
                        if !viewModel.puzzleTechniques.isEmpty {
                            Image(systemName: "info.circle")
                                .imageScale(.small)
                        }
                    }
                    .font(fontOption.font(for: .subheadline))
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        if !viewModel.puzzleTechniques.isEmpty {
                            showTechniques = true
                        }
                    }
                    .popover(isPresented: $showTechniques) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Techniques")
                                .font(fontOption.font(for: .headline))
                                .foregroundStyle(accentColor)
                            ForEach(viewModel.puzzleTechniques, id: \.self) { technique in
                                let name = SudokuTechnique(rawValue: technique)?.title ?? technique.replacingOccurrences(of: "_", with: " ").capitalized
                                Text(verbatim: "• \(name)")
                                    .font(fontOption.font(for: .body))
                            }
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
            
            Spacer()
            
            Label(viewModel.formattedElapsedTime, systemImage: "clock")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .font(fontOption.font(size: Style.remainingCountFontSize).weight(.medium))
            
            Label("\(viewModel.hintCount)", systemImage: "lightbulb.fill")
                .foregroundStyle(.orange)
                .lineLimit(1)
                .font(fontOption.font(size: Style.remainingCountFontSize).weight(.medium))
            
            Label("\(viewModel.errorCount)", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .lineLimit(1)
                .font(fontOption.font(size: Style.remainingCountFontSize).weight(.medium))
            
            Button {
                viewModel.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(fontOption.font(size: Style.keyFontSize))
                    .foregroundStyle(viewModel.canUndo ? accentColor : .gray.opacity(Style.disabledOpacity))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canUndo)
            .accessibilityLabel("Undo")
        }
    }
}

#Preview {
    let vm = PuzzleViewModel(puzzle: .sample)
    vm.puzzleNumber = 42
    vm.puzzleDifficulty = "medium"
    return HeaderView(viewModel: vm)
        .padding()
}
