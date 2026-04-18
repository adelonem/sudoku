//
//  VictoryView.swift
//  Sudoku
//

import SwiftUI

struct VictoryView: View {
    var viewModel: PuzzleViewModel
    var onNewGame: () -> Void
    @Environment(\.customFontOption) private var fontOption
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.3 : 0)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 0.4), value: appeared)
            
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(fontOption.font(size: 64))
                    .foregroundStyle(.yellow)
                
                Text("Congratulations!")
                    .font(fontOption.font(for: .largeTitle).bold())
                
                Text("You successfully solved the puzzle.")
                    .font(fontOption.font(for: .title3))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    onNewGame()
                } label: {
                    Label("New Random Puzzle", systemImage: "arrow.trianglehead.2.counterclockwise")
                        .font(fontOption.font(for: .title3).bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 8)
            }
            .padding(40)
            .background(Style.background, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
            
            FireworksOverlay()
        }
        .onAppear {
            appeared = true
        }
    }
}

#Preview {
    VictoryView(viewModel: PuzzleViewModel(puzzle: .sample), onNewGame: {})
}
