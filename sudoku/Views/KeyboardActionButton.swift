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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.callout)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.opacity(isActive ? 0.3 : 0.15))
                )
        }
        .buttonStyle(.plain)
    }
}
