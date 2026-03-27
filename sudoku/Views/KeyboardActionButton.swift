//
//  KeyboardActionButton.swift
//  sudoku
//

import SwiftUI

/// A reusable action button for the keyboard toolbar row.
struct KeyboardActionButton: View {
    let icon: String
    var isActive: Bool = false
    let tint: Color
    var square: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.callout)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(square ? 1.0 : nil, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: Style.keyCornerRadius)
                        .fill(tint.opacity(isActive ? Style.highlightOpacity : Style.inactiveBackgroundOpacity))
                )
        }
        .buttonStyle(.plain)
    }
}
