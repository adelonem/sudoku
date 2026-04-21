//
//  ContentView.swift
//  Sudoku
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PuzzleViewModel(puzzle: .sample)
    @State private var keyboardWidth: CGFloat?
    @State private var showNewGame = false
    @State private var showCompletedPuzzles = false
    @State private var showTutorial = false
    @State private var hasPresentedInitialTutorial = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("accentColorName") private var selectedColorName = "Blue"
    @AppStorage("fontOptionRawValue") private var selectedFontRawValue = FontOption.standard.rawValue
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    
    private var customAccentColor: Color {
        Style.accentColors.first { $0.name == selectedColorName }?.color
        ?? Style.accentColors[0].color
    }
    
    private var fontOption: FontOption {
        FontOption(rawValue: selectedFontRawValue) ?? .standard
    }
    
    private var showHintsView: Binding<Bool> {
        Binding(
            get: { viewModel.isShowingHint },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearHint()
                }
            }
        )
    }
    
    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.width < geo.size.height
            
            if isPortrait {
                VStack(spacing: 20) {
                    HeaderView(viewModel: viewModel)
                    
                    PuzzleView(viewModel: viewModel)
                        .layoutPriority(1)
                    
                    KeyboardView(viewModel: viewModel, isPortrait: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .bottom) {
                    PuzzleView(viewModel: viewModel)
                        .layoutPriority(1)
                    
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
        .overlay(alignment: .bottom) {
            TrivialBannerView(viewModel: viewModel)
                .opacity(viewModel.isPuzzleTrivial ? 1 : 0)
                .offset(y: viewModel.isPuzzleTrivial ? 0 : 40)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isPuzzleTrivial)
                .allowsHitTesting(viewModel.isPuzzleTrivial)
                .padding(.bottom, 8)
        }
        .overlay {
            if viewModel.isSolved {
                VictoryView(viewModel: viewModel) {
                    viewModel.newGame()
                }
            }
        }
        .onAppear {
            viewModel.load()
            presentTutorialIfNeeded()
        }
        .onChange(of: showNewGame) {
            updateTimerState()
        }
        .onChange(of: showCompletedPuzzles) {
            updateTimerState()
        }
        .onChange(of: showTutorial) {
            updateTimerState()
        }
        .onChange(of: viewModel.isShowingHint) {
            updateTimerState()
        }
        .onChange(of: scenePhase) {
            updateTimerState()
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
        .navigationDestination(isPresented: $showTutorial) {
            TutorialView()
                .tint(customAccentColor)
                .environment(\.customAccentColor, customAccentColor)
                .environment(\.customFontOption, fontOption)
        }
        .navigationDestination(isPresented: showHintsView) {
            HintsView(viewModel: viewModel)
                .tint(customAccentColor)
                .environment(\.customAccentColor, customAccentColor)
                .environment(\.customFontOption, fontOption)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showNewGame = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .accessibilityLabel("New Game")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showCompletedPuzzles = true
                } label: {
                    Image(systemName: "trophy")
                }
                .accessibilityLabel("Completed Puzzles")
                .accessibilityIdentifier("completedPuzzlesButton")
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        openTutorial()
                    } label: {
                        Label("How to Play", systemImage: "questionmark.circle")
                    }
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Information")
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
                .accessibilityLabel("Font")
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Color", selection: $selectedColorName) {
                        ForEach(Style.accentColors, id: \.name) { entry in
                            Image(systemName: "circle.fill")
                                .tint(entry.color)
                                .tag(entry.name)
                                .accessibilityLabel(entry.localizedName)
                        }
                    }
                    .pickerStyle(.palette)
                } label: {
                    Image(systemName: "paintpalette")
                        .symbolRenderingMode(.multicolor)
                }
                .accessibilityLabel("Color")
            }
        }
    }
    
    private func updateTimerState() {
        if scenePhase == .active,
           !showNewGame,
           !showCompletedPuzzles,
           !showTutorial,
           !viewModel.isShowingHint {
            viewModel.startTimer()
        } else {
            viewModel.stopTimer()
        }
    }
    
    private func presentTutorialIfNeeded() {
        guard !hasPresentedInitialTutorial else { return }
        hasPresentedInitialTutorial = true
        
        if !hasSeenTutorial {
            openTutorial()
        }
    }
    
    private func openTutorial() {
        hasSeenTutorial = true
        showTutorial = true
    }
}

#Preview {
    ContentView()
}
