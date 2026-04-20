//
//  HintCalloutView.swift
//  Sudoku
//

import SwiftUI

/// A callout bubble with a directional arrow that points toward the hinted cell(s).
/// Hold down (tap & hold) to dim the callout and see the board underneath.
struct HintCalloutView: View {
    var viewModel: PuzzleViewModel
    let hint: HintResult
    let arrowAtBottom: Bool
    let arrowRatio: CGFloat
    
    @Environment(\.customFontOption) private var fontOption
    @Environment(\.colorScheme) private var colorScheme
    @GestureState private var isDimmed = false
    
    private let arrowW: CGFloat = 16
    private let arrowH: CGFloat = 9
    private let radius: CGFloat = 14
    
    var body: some View {
        VStack(spacing: 0) {
            mainContent
            if viewModel.activeHintChain.count > 1 {
                Divider().padding(.horizontal, 16)
                navigationStrip
            }
        }
        .padding(.top,    arrowAtBottom ? 12 : (arrowH + 12))
        .padding(.bottom, arrowAtBottom ? (arrowH + 12) : 12)
        .background {
            CalloutBubble(
                arrowAtBottom: arrowAtBottom,
                arrowRatio: arrowRatio,
                cornerRadius: radius,
                arrowWidth: arrowW,
                arrowHeight: arrowH
            )
            .fill(Style.background)
            .overlay {
                CalloutBubble(
                    arrowAtBottom: arrowAtBottom,
                    arrowRatio: arrowRatio,
                    cornerRadius: radius,
                    arrowWidth: arrowW,
                    arrowHeight: arrowH
                )
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.25 : 0.1), lineWidth: 1)
            }
            .shadow(
                color: colorScheme == .dark ? .white.opacity(0.15) : .black.opacity(0.35),
                radius: colorScheme == .dark ? 12 : 10,
                x: 0,
                y: colorScheme == .dark ? 0 : 4
            )
        }
        .opacity(isDimmed ? 0.12 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isDimmed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDimmed) { _, state, _ in state = true }
        )
    }
    
    // MARK: - Content
    
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(fontOption.font(size: 22).weight(.medium))
                .foregroundStyle(.orange)
                .padding(.top, 1)
            
            HintContentView(hint: hint)
            
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
        .padding(.bottom, viewModel.activeHintChain.count > 1 ? 8 : 0)
    }
    
    private var navigationStrip: some View {
        HStack(spacing: 16) {
            Button { viewModel.prevHint() } label: {
                Image(systemName: "chevron.left")
                    .font(fontOption.font(size: 16).weight(.semibold))
            }
            .disabled(!viewModel.canGoPrevHint)
            .buttonStyle(.plain)
            
            Text("\(viewModel.activeHintIndex + 1) / \(viewModel.activeHintChain.count)")
                .font(fontOption.font(for: .caption).monospacedDigit())
                .foregroundStyle(.secondary)
            
            Button { viewModel.nextHint() } label: {
                Image(systemName: "chevron.right")
                    .font(fontOption.font(size: 16).weight(.semibold))
            }
            .disabled(!viewModel.canGoNextHint)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}
