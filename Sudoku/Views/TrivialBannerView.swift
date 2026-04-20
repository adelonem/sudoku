//
//  TrivialBannerView.swift
//  Sudoku
//

import SwiftUI

struct TrivialBannerView: View {
    var viewModel: PuzzleViewModel
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(fontOption.font(size: 22).weight(.medium))
                .foregroundStyle(accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Puzzle can be auto-completed!")
                    .font(fontOption.font(for: .subheadline).weight(.semibold))
                Text("Tap to finish automatically")
                    .font(fontOption.font(for: .caption))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                viewModel.dismissAutoComplete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(fontOption.font(size: 22))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Style.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 12)
        .onTapGesture {
            viewModel.acceptAutoComplete()
        }
    }
}
