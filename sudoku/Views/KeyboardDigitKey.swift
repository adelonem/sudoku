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
    
    var body: some View {
        Button {
            if game.digitFirstDigit != nil {
                game.toggleDigitFirst(number)
            } else {
                game.enterDigit(number)
            }
        } label: {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(game.isNoteMode ? Color.orange : Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(isActive ? 0.4 : 0.15))
                )
        }
        .buttonStyle(.plain)
    }
}
