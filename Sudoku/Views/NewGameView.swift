//
//  NewGameView.swift
//  Sudoku
//

import SwiftUI

struct NewGameView: View {
    private static let difficultyOptions = ["easy", "medium", "hard", "expert", "extreme", "diabolic"]
    
    var viewModel: PuzzleViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.customFontOption) private var fontOption
    
    @State private var idInput: String = ""
    @State private var showError: Bool = false
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Difficulty")
                            .font(fontOption.font(for: .subheadline))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 12) {
                            ForEach(Self.difficultyOptions, id: \.self) { difficulty in
                                Button {
                                    startNewGame(difficulty: difficulty)
                                } label: {
                                    Text(localizedDifficulty(difficulty))
                                        .font(fontOption.font(for: .title3).bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 32)
                
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
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 32)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) {
            loadPuzzleButton
                .padding(.horizontal, 32)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(.bar)
        }
#if os(iOS)
        .scrollDismissesKeyboard(.interactively)
#endif
        .navigationTitle("New Game")
    }
    
    private var trimmedIDInput: String {
        idInput.trimmingCharacters(in: .whitespaces)
    }
    
    private var loadPuzzleButton: some View {
        Button {
            tryLoadByID()
        } label: {
            Text("Load Puzzle")
                .font(fontOption.font(for: .title3).bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(trimmedIDInput.isEmpty)
    }
    
    private func tryLoadByID() {
        isFieldFocused = false
        let id = Int(trimmedIDInput)
        if let id, viewModel.loadGameByID(id) {
            dismiss()
        } else {
            showError = true
        }
    }
    
    private func startNewGame(difficulty: String) {
        viewModel.newGame(difficulty: difficulty)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NewGameView(viewModel: PuzzleViewModel(puzzle: .sample))
    }
}
