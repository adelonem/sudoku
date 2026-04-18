//
//  KeyboardActionButtonView.swift
//  Sudoku
//

import SwiftUI

/// A reusable action button for the keyboard toolbar row.
struct KeyboardActionButtonView: View {
    let icon: String
    var isActive: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(fontOption.font(size: Style.keyFontSize))
                .minimumScaleFactor(0.1)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .opacity(isDisabled ? Style.disabledOpacity : 1.0)
                .foregroundStyle(isActive ? accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
