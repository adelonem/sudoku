//
//  NewGameView.swift
//  Sudoku
//

import SwiftUI

struct NewGameView: View {
    var viewModel: PuzzleViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.customFontOption) private var fontOption
    
    @State private var idInput: String = ""
    @State private var showError: Bool = false
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Spacer()
                Button {
                    viewModel.newGame()
                    dismiss()
                } label: {
                    Label("New Random Puzzle", systemImage: "arrow.trianglehead.2.counterclockwise")
                        .font(fontOption.font(for: .title3).bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 12) {
                Text("Or enter a puzzle ID")
                    .font(fontOption.font(for: .subheadline))
                    .foregroundStyle(.secondary)
                
                TextField("Puzzle ID", text: $idInput)
                    .font(fontOption.font(for: .body))
                    .textFieldStyle(.roundedBorder)
                    .focused($isFieldFocused)
                    .onChange(of: idInput) { showError = false }
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                
                if showError {
                    Text("This puzzle doesn't exist.")
                        .font(fontOption.font(for: .caption))
                        .foregroundStyle(.red)
                }
                
                Button {
                    tryLoadByID()
                } label: {
                    Text("Load Puzzle")
                        .font(fontOption.font(for: .title3).bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(idInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
        }
        .navigationTitle("New Game")
    }
    
    private func tryLoadByID() {
        isFieldFocused = false
        let id = Int(idInput.trimmingCharacters(in: .whitespaces))
        if let id, viewModel.loadGameByID(id) {
            dismiss()
        } else {
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        NewGameView(viewModel: PuzzleViewModel(puzzle: .sample))
    }
}
