//
//  HintKeyboardView.swift
//  Sudoku
//

import SwiftUI

/// Replaces the digit keyboard while a hint is active.
/// Mirrors the exact dimensions of the normal keyboard (action row + digit grid)
/// so swapping modes does not shift the puzzle layout. The digit-grid area is
/// repurposed to display the technique name and impacted digits.
struct HintKeyboardView: View {
    var viewModel: PuzzleViewModel
    var isPortrait: Bool = false
    
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        if isPortrait {
            portraitLayout
        } else {
            landscapeLayout
        }
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 10) {
            actionRow
            Grid(horizontalSpacing: 4, verticalSpacing: 0) {
                GridRow {
                    ForEach(0..<Puzzle.size, id: \.self) { _ in
                        hiddenKey(aspectRatio: 1.5)
                    }
                }
            }
            .overlay { infoOverlay }
        }
    }
    
    private var landscapeLayout: some View {
        VStack(spacing: 4) {
            actionRow
            ForEach(0..<Puzzle.blockSize, id: \.self) { _ in
                HStack(spacing: 4) {
                    ForEach(0..<Puzzle.blockSize, id: \.self) { _ in
                        hiddenKey(aspectRatio: 1.0)
                    }
                }
            }
        }
        .overlay {
            // The outer VStack has 4 equally-flexible rows (1 action + 3 digit) and 3
            // spacings of 4 pt, exactly like the digit keyboard. Compute the digit-grid
            // bounds from the rendered size so the info card occupies the same
            // footprint as the 3x3 grid would.
            GeometryReader { geo in
                let cellHeight = max(0, (geo.size.height - 12) / 4)
                let digitGridTop = cellHeight + 4
                let digitGridHeight = max(0, 3 * cellHeight + 8)
                infoOverlay
                    .frame(width: geo.size.width, height: digitGridHeight)
                    .offset(y: digitGridTop)
            }
        }
    }
    
    /// An invisible placeholder that mirrors the dimensions of a real KeyboardKeyView
    /// so the hint keyboard occupies the exact same footprint as the digit keyboard.
    private func hiddenKey(aspectRatio: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text("0")
                .font(fontOption.font(size: Style.keyFontSize))
                .lineLimit(1)
            Text("0")
                .font(fontOption.font(size: Style.remainingCountFontSize))
                .lineLimit(1)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1.0 / aspectRatio, contentMode: .fit)
        .opacity(0)
    }
    
    private var actionRow: some View {
        HStack(spacing: 4) {
            KeyboardActionButtonView(
                icon: "chevron.left",
                accessibilityLabel: "Previous hint",
                isDisabled: !viewModel.canGoPrevHint
            ) {
                viewModel.prevHint()
            }
            
            KeyboardActionButtonView(
                icon: "xmark",
                accessibilityLabel: "Dismiss hint"
            ) {
                viewModel.clearHint()
            }
            
            if viewModel.isOnLastHintStep {
                KeyboardActionButtonView(
                    icon: "checkmark",
                    accessibilityLabel: "Finish hint",
                    isActive: true
                ) {
                    viewModel.finishHint()
                }
            } else {
                KeyboardActionButtonView(
                    icon: "chevron.right",
                    accessibilityLabel: "Next hint",
                    isDisabled: !viewModel.canGoNextHint
                ) {
                    viewModel.nextHint()
                }
            }
        }
    }
    
    private var infoOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(accentColor.opacity(0.12))
            .overlay {
                if let hint = viewModel.activeHint {
                    VStack(spacing: 4) {
                        Text(hint.technique.title)
                            .font(fontOption.font(for: .headline).weight(.semibold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(2)
                        
                        Text(impactedDigitsText(for: hint))
                            .font(fontOption.font(for: .subheadline).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        
                        Text("\(viewModel.activeHintIndex + 1) / \(viewModel.activeHintChain.count)")
                            .font(fontOption.font(for: .caption).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                }
            }
    }
    
    private func impactedDigitsText(for hint: HintResult) -> String {
        let digits = impactedDigits(for: hint)
        let formatted = digits.map { String($0) }.joined(separator: ", ")
        if digits.count <= 1 {
            return String(localized: "digit \(formatted)")
        }
        return String(localized: "digits \(formatted)")
    }
    
    private func impactedDigits(for hint: HintResult) -> [Int] {
        if let digit = hint.digit {
            return [digit]
        }
        return Array(Set(hint.eliminations.map(\.digit))).sorted()
    }
}

#Preview("Portrait") {
    let vm = PuzzleViewModel(puzzle: .sample)
    vm.requestHint()
    return HintKeyboardView(viewModel: vm, isPortrait: true)
        .frame(width: 360)
        .padding()
}

#Preview("Landscape") {
    let vm = PuzzleViewModel(puzzle: .sample)
    vm.requestHint()
    return HintKeyboardView(viewModel: vm)
        .frame(width: 220)
        .padding()
}
