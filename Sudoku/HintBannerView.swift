//
//  HintBannerView.swift
//  Sudoku
//

import SwiftUI

struct HintBannerView: View {
    var viewModel: PuzzleViewModel
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        if let hint = viewModel.activeHint {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(fontOption.font(size: 22).weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.top, 1)
                
                HintContentView(hint: hint)
                
                Spacer(minLength: 0)
                
                Button {
                    viewModel.clearHint()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(fontOption.font(size: 22))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss hint")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Style.background, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
            .padding(.horizontal, 12)
        }
    }
}
