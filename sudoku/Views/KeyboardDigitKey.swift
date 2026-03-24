//
//  KeyboardDigitKey.swift
//  sudoku
//

import SwiftUI

/// A digit key that enters the number on tap.
/// In digit-first mode, tap selects the active digit instead.
struct KeyboardDigitKey: View {
    let number: Int
    let game: Game
    
    private var isActive: Bool {
        game.digitFirstDigit == number
    }
    
    private var remaining: Int {
        game.remainingCount(for: number)
    }
    
    private var isExhausted: Bool {
        remaining == 0
    }
    
    var body: some View {
        Button {
            if game.digitFirstDigit != nil {
                if game.digitFirstDigit != number {
                    game.toggleDigitFirst(number)
                }
            } else {
                game.enterDigit(number)
            }
        } label: {
            VStack(spacing: 0) {
                Text("\(number)")
                    .font(.title2)
                    .fontWeight(.medium)
                Text("(\(remaining))")
                    .font(.caption2)
                    .fontWeight(.regular)
            }
            .foregroundStyle(
                isExhausted ? Color.gray.opacity(0.4) :
                    game.isNoteMode ? Color.orange : Color.primary
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(isActive ? 0.4 : 0.15))
            )
        }
        .buttonStyle(.plain)
        .disabled(isExhausted)
    }
}
