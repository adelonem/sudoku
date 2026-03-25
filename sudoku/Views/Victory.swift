//
//  Victory.swift
//  sudoku
//

import SwiftUI

struct Victory: View {
    var onNewGame: () -> Void
    
    private static let backgroundColor: Color = {
#if os(macOS)
        Color(nsColor: .textBackgroundColor)
#else
        Color(.systemBackground)
#endif
    }()
    
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
            
            Button {
                onNewGame()
            } label: {
                Label("New Game", systemImage: "arrow.trianglehead.2.counterclockwise")
                    .font(.title3.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .background(Self.backgroundColor, in: RoundedRectangle(cornerRadius: 20))
    }
}
