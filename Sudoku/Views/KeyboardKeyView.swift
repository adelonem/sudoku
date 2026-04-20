//
//  KeyboardKeyView.swift
//  Sudoku
//

import SwiftUI

/// A key that selects a digit for placement on the grid.
struct KeyboardKeyView: View {
    let number: Int
    var aspectRatio: CGFloat = 1.0
    var viewModel: PuzzleViewModel
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    private var isActive: Bool {
        viewModel.selectedDigit == number
    }
    
    private var remaining: Int {
        viewModel.remainingCount(for: number)
    }
    
    private var isExhausted: Bool {
        remaining == 0
    }
    
    var body: some View {
        Button {
            viewModel.selectedRow = nil
            viewModel.selectedCol = nil
            viewModel.selectDigit(number)
        } label: {
            VStack(spacing: 0) {
                Text("\(number)")
                    .font(fontOption.font(size: Style.keyFontSize))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .fontWeight(.medium)
                    .foregroundStyle(accentColor)
                Text("\(remaining)")
                    .font(fontOption.font(size: Style.remainingCountFontSize))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .fontWeight(.regular)
                    .foregroundStyle(Color.secondary)
            }
            .padding(2)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1.0 / aspectRatio, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(isActive ? Style.disabledOpacity : Style.inactiveBackgroundOpacity))
            )
        }
        .buttonStyle(.plain)
        .disabled(isExhausted)
        .opacity(isExhausted ? 0 : 1)
    }
}
