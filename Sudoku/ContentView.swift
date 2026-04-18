//
//  ContentView.swift
//  Sudoku
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PuzzleViewModel(puzzle: .sample)
    @State private var keyboardWidth: CGFloat?
    @State private var puzzleGridFrame: CGRect = .zero
    @State private var showNewGame = false
    @State private var showCompletedPuzzles = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("accentColorName") private var selectedColorName = "Blue"
    @AppStorage("fontOptionRawValue") private var selectedFontRawValue = FontOption.standard.rawValue
    
    @ViewBuilder
    private func hintCalloutOverlay(hint: HintResult) -> some View {
        GeometryReader { geo in
            let globalOrigin = geo.frame(in: .global).origin
            let pf = CGRect(
                x: puzzleGridFrame.minX - globalOrigin.x,
                y: puzzleGridFrame.minY - globalOrigin.y,
                width: puzzleGridFrame.width,
                height: puzzleGridFrame.height
            )
            
            let rows = hint.primaryCells.map { Double($0.row) }
            let cols = hint.primaryCells.map { Double($0.col) }
            let avgRow = rows.reduce(0, +) / Double(rows.count)
            let avgCol = cols.reduce(0, +) / Double(cols.count)
            let minRow = rows.min()!
            let maxRow = rows.max()!
            
            let wAlloc   = pf.width  / 9
            let hAlloc   = pf.height / 9
            let cellSize = min(wAlloc, hAlloc)
            let hGap     = max(0, (wAlloc - cellSize) / 2)
            let vGap     = max(0, (hAlloc - cellSize) / 2)
            
            let arrowAtBottom = avgRow >= 4.0
            let hPad: CGFloat = 8
            
            let leadingPad  = pf.minX + hGap + hPad
            let trailingPad = geo.size.width - pf.maxX + hGap + hPad
            let calloutW    = max(pf.width - 2 * hGap - 2 * hPad, 1)
            
            let cellCenterX = pf.minX + CGFloat(avgCol + 0.5) * wAlloc
            let arrowRatio  = min(max((cellCenterX - leadingPad) / calloutW, 0.1), 0.9)
            
            let arrowTipY = arrowAtBottom
            ? pf.minY + CGFloat(minRow) * hAlloc + vGap
            : pf.minY + CGFloat(maxRow + 1) * hAlloc - vGap
            
            if arrowAtBottom {
                VStack(spacing: 0) {
                    HintCalloutView(viewModel: viewModel, hint: hint,
                                    arrowAtBottom: true, arrowRatio: arrowRatio)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, leadingPad)
                    .padding(.trailing, trailingPad)
                    .frame(height: max(arrowTipY, 1),
                           alignment: .bottom)
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 0) {
                    Color.clear.frame(height: max(arrowTipY, 0))
                    HintCalloutView(viewModel: viewModel, hint: hint,
                                    arrowAtBottom: false, arrowRatio: arrowRatio)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, leadingPad)
                    .padding(.trailing, trailingPad)
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private var customAccentColor: Color {
        Style.accentColors.first { $0.name == selectedColorName }?.color
        ?? Style.accentColors[0].color
    }
    
    private var fontOption: FontOption {
        FontOption(rawValue: selectedFontRawValue) ?? .standard
    }
    
    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.width < geo.size.height
            
            if isPortrait {
                VStack(spacing: 20) {
                    HeaderView(viewModel: viewModel)
                    
                    PuzzleView(viewModel: viewModel)
                        .layoutPriority(1)
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { puzzleGridFrame = $0 }
                    
                    KeyboardView(viewModel: viewModel, isPortrait: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .bottom) {
                    PuzzleView(viewModel: viewModel)
                        .layoutPriority(1)
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { puzzleGridFrame = $0 }
                    
                    VStack(spacing: 8) {
                        HeaderView(viewModel: viewModel)
                            .frame(maxWidth: keyboardWidth)
                        KeyboardView(viewModel: viewModel)
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.width
                            } action: { width in
                                keyboardWidth = width
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay {
            if viewModel.isSolved {
                VictoryView(viewModel: viewModel) {
                    viewModel.newGame()
                }
            }
        }
        .overlay {
            if viewModel.isShowingHint, let hint = viewModel.activeHint,
               !hint.primaryCells.isEmpty, puzzleGridFrame != .zero {
                hintCalloutOverlay(hint: hint)
                    .transition(.opacity)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8),
                               value: viewModel.isShowingHint)
            }
        }
        .overlay(alignment: .bottom) {
            TrivialBannerView(viewModel: viewModel)
                .opacity(viewModel.isPuzzleTrivial ? 1 : 0)
                .offset(y: viewModel.isPuzzleTrivial ? 0 : 40)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isPuzzleTrivial)
                .allowsHitTesting(viewModel.isPuzzleTrivial)
                .padding(.bottom, 8)
        }
        .onAppear {
            viewModel.load()
        }
        .onChange(of: showNewGame) {
            if showNewGame { viewModel.stopTimer() } else { viewModel.startTimer() }
        }
        .onChange(of: showCompletedPuzzles) {
            if showCompletedPuzzles { viewModel.stopTimer() } else { viewModel.startTimer() }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active, !showNewGame, !showCompletedPuzzles {
                viewModel.startTimer()
            } else {
                viewModel.stopTimer()
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 4)
        .tint(customAccentColor)
        .environment(\.customAccentColor, customAccentColor)
        .environment(\.customFontOption, fontOption)
        .navigationDestination(isPresented: $showNewGame) {
            NewGameView(viewModel: viewModel)
                .tint(customAccentColor)
                .environment(\.customFontOption, fontOption)
        }
        .navigationDestination(isPresented: $showCompletedPuzzles) {
            CompletedPuzzlesView(viewModel: viewModel)
                .tint(customAccentColor)
                .environment(\.customFontOption, fontOption)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showNewGame = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showCompletedPuzzles = true
                } label: {
                    Image(systemName: "trophy")
                }
                .accessibilityIdentifier("completedPuzzlesButton")
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Font", selection: $selectedFontRawValue) {
                        ForEach(FontOption.allCases, id: \.rawValue) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: "textformat")
                }
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Color", selection: $selectedColorName) {
                        ForEach(Style.accentColors, id: \.name) { entry in
                            Image(systemName: "circle.fill")
                                .tint(entry.color)
                                .tag(entry.name)
                        }
                    }
                    .pickerStyle(.palette)
                } label: {
                    Image(systemName: "paintpalette")
                        .symbolRenderingMode(.multicolor)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
