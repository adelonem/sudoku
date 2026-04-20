//
//  HintsView.swift
//  Sudoku
//

import SwiftUI

struct HintsView: View {
    var viewModel: PuzzleViewModel
    
    @Environment(\.customAccentColor) private var accentColor
    @Environment(\.customFontOption) private var fontOption
    
    var body: some View {
        Group {
            if let hint = viewModel.activeHint {
                GeometryReader { geo in
                    let isLandscape = geo.size.width > geo.size.height
                    
                    Group {
                        if isLandscape {
                            HStack(alignment: .top, spacing: 20) {
                                landscapeBoardSection(hint: hint)
                                landscapeDetailsSection(hint: hint)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(20)
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    boardSection(hint: hint)
                                    detailsSection(hint: hint)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No Hint", systemImage: "lightbulb.slash")
                        .font(fontOption.font(for: .headline))
                } description: {
                    Text("Return to continue solving the current puzzle.")
                        .font(fontOption.font(for: .subheadline))
                }
            }
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Hints")
        .safeAreaInset(edge: .bottom) {
            if viewModel.isShowingHint {
                navigationStrip
            }
        }
    }
    
    private func boardSection(hint: HintResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let previewPuzzle = viewModel.hintPreviewPuzzle {
                HintBoardView(
                    puzzle: previewPuzzle,
                    hint: hint,
                    highlightedDigit: hint.digit
                )
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(cardBackground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func detailsSection(hint: HintResult) -> some View {
        detailsContent(hint: hint)
            .background(cardBackground)
    }
    
    private func detailsContent(hint: HintResult) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(fontOption.font(for: .title3).weight(.semibold))
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hint \(viewModel.activeHintIndex + 1) of \(viewModel.activeHintChain.count)")
                        .font(fontOption.font(for: .subheadline))
                        .foregroundStyle(.secondary)
                    
                    if let digit = hint.digit {
                        Text("Focus on digit \(digit)")
                            .font(fontOption.font(for: .headline))
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            hintProgressSummary(for: hint)
            hintLegend
            HintContentView(hint: hint)
            hintActionSummary(for: hint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
    
    private func landscapeBoardSection(hint: HintResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Board", systemImage: "square.grid.3x3")
                .font(fontOption.font(for: .headline))
                .foregroundStyle(.secondary)
            
            if let previewPuzzle = viewModel.hintPreviewPuzzle {
                HintBoardView(
                    puzzle: previewPuzzle,
                    hint: hint,
                    highlightedDigit: hint.digit
                )
                .padding(14)
                .background(cardBackground)
            }
            
            hintProgressSummary(for: hint)
            hintLegend
        }
    }
    
    private func landscapeDetailsSection(hint: HintResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(fontOption.font(for: .title3).weight(.semibold))
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hint \(viewModel.activeHintIndex + 1) of \(viewModel.activeHintChain.count)")
                            .font(fontOption.font(for: .subheadline))
                            .foregroundStyle(.secondary)
                        
                        if let digit = hint.digit {
                            Text("Focus on digit \(digit)")
                                .font(fontOption.font(for: .headline))
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                HintContentView(hint: hint)
                hintActionSummary(for: hint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(cardBackground)
    }
    
    private var hintLegend: some View {
        HStack(spacing: 16) {
            legendItem(
                color: Color.orange.opacity(Style.highlightOpacity),
                label: "Target cells"
            )
            legendItem(
                color: Color.orange.opacity(Style.peerHighlightOpacity),
                label: "Support cells"
            )
        }
        .font(fontOption.font(for: .caption))
        .foregroundStyle(.secondary)
    }
    
    private var navigationStrip: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                Button {
                    viewModel.prevHint()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(fontOption.font(for: .body).weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canGoPrevHint)
                .accessibilityLabel("Previous hint")
                
                Text("\(viewModel.activeHintIndex + 1) / \(viewModel.activeHintChain.count)")
                    .font(fontOption.font(for: .subheadline).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 72)
                
                Button {
                    viewModel.nextHint()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(fontOption.font(for: .body).weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canGoNextHint)
                .accessibilityLabel("Next hint")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(.thinMaterial)
    }
    
    private func hintProgressSummary(for hint: HintResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(progressTitle)
                .font(fontOption.font(for: .subheadline).weight(.semibold))
            Text(progressDescription(for: hint))
                .font(fontOption.font(for: .caption))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }
    
    private func hintActionSummary(for hint: HintResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current action")
                .font(fontOption.font(for: .subheadline).weight(.semibold))
            
            if hint.eliminations.isEmpty {
                Text("No candidates are removed on this step. Use the remaining possibility in the highlighted cell.")
                    .font(fontOption.font(for: .caption))
                    .foregroundStyle(.secondary)
            } else {
                Text(actionSummary(for: hint.eliminations))
                    .font(fontOption.font(for: .caption))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.06))
        )
    }
    
    private var progressTitle: String {
        if viewModel.hintAppliedActionCount == 0 {
            return String(localized: "Starting board")
        }
        return viewModel.hintAppliedActionCount == 1
        ? String(localized: "1 action already applied")
        : String(localized: "\(viewModel.hintAppliedActionCount) actions already applied")
    }
    
    private func progressDescription(for hint: HintResult) -> String {
        if viewModel.hintAppliedActionCount == 0 {
            return String(localized: "All valid candidates are visible. Advance through the hints to see each elimination applied to this board.")
        }
        if hint.eliminations.isEmpty {
            return String(localized: "Previous eliminations are already reflected on the board. The current step is now a placement.")
        }
        return String(localized: "The board already reflects the previous eliminations. The highlighted action explains the next candidates to remove.")
    }
    
    private func actionSummary(for eliminations: [(row: Int, col: Int, digit: Int)]) -> String {
        struct CellKey: Hashable {
            let row: Int
            let col: Int
        }
        
        let groupedByCell = Dictionary(grouping: eliminations) { elimination in
            CellKey(row: elimination.row, col: elimination.col)
        }
        
        let labels = groupedByCell
            .sorted { lhs, rhs in
                lhs.key.row == rhs.key.row ? lhs.key.col < rhs.key.col : lhs.key.row < rhs.key.row
            }
            .map { key, entries in
                let digitLabels = entries.map { String($0.digit) }.sorted()
                let digits = digitLabels.joined(separator: ", ")
                return "R\(key.row + 1)C\(key.col + 1): \(digits)"
            }
            .joined(separator: " • ")
        
        return eliminations.count == 1
        ? String(localized: "Remove candidate \(eliminations[0].digit) from \(labels).")
        : String(localized: "Remove these candidates: \(labels).")
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(0.14),
                accentColor.opacity(0.05),
                Style.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Style.background)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accentColor.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color)
                .frame(width: 18, height: 18)
            
            Text(label)
        }
    }
}

#Preview {
    NavigationStack {
        let viewModel = PuzzleViewModel(puzzle: .sample)
        HintsView(viewModel: viewModel)
            .environment(\.customAccentColor, Style.accentColors[0].color)
            .environment(\.customFontOption, .standard)
    }
}
