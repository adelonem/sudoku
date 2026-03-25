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
                .if(square) { view in
                    view.aspectRatio(1.0, contentMode: .fit)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.opacity(isActive ? 0.3 : 0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
