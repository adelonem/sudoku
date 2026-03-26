//
//  KeyboardKey.swift
//  sudoku
//

import SwiftUI

/// A key that enters a digit on tap, or selects it as the locked action.
struct KeyboardKey: View {
    let number: Int
    let game: Game
    
    private var isActive: Bool {
        game.lockedAction == .digit(number)
    }
    
    private var remaining: Int {
        game.remainingCount(for: number)
    }
    
    private var isExhausted: Bool {
        remaining == 0
    }
    
    var body: some View {
        Button {
            if game.isLockedMode {
                game.setLockedAction(.digit(number))
            } else {
                game.enterDigit(number)
            }
        } label: {
            VStack(spacing: 0) {
                Text("\(number)")
                    .font(.system(size: 36))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .fontWeight(.medium)
                Text("(\(remaining))")
                    .font(.system(size: 18))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .fontWeight(.regular)
            }
            .padding(2)
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
