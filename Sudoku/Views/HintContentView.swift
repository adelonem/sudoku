//
//  HintContentView.swift
//  Sudoku
//

import SwiftUI

/// Shared view that renders hint content: title, difficulty, explanation, and step-by-step reasoning.
/// Used by the dedicated hints screen and any compact hint presentations.
struct HintContentView: View {
    let hint: HintResult
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(hint.title)
                    .font(fontOption.font(for: .subheadline).weight(.semibold))
                Text("· \(hint.technique.difficulty)")
                    .font(fontOption.font(for: .caption))
                    .foregroundStyle(.secondary)
            }
            
            Text(hint.explanation)
                .font(fontOption.font(for: .caption))
                .foregroundStyle(.primary)
            
            if !hint.reasoning.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(hint.reasoning.enumerated()), id: \.offset) { index, step in
                        if step.hasPrefix("→") {
                            Text(step)
                                .font(fontOption.font(for: .caption).weight(.medium))
                                .foregroundStyle(.orange)
                        } else {
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(index + 1).")
                                    .font(fontOption.font(for: .caption).monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 16, alignment: .trailing)
                                Text(step)
                                    .font(fontOption.font(for: .caption))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}
