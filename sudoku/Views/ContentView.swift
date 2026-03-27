//
//  ContentView.swift
//  sudoku
//

import SwiftUI

struct ContentView: View {
    @Environment(Game.self) private var game
    @State private var keyboardWidth: CGFloat?
    
    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.width < geo.size.height
            
            if isPortrait {
                VStack(spacing: 12) {
                    Header()
                    
                    PuzzleGrid()
                        .layoutPriority(1)
                    
                    Keyboard(isPortrait: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .bottom) {
                    PuzzleGrid()
                        .layoutPriority(1)
                    
                    VStack(spacing: 8) {
                        Header()
                            .frame(maxWidth: keyboardWidth)
                        Keyboard()
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
        .overlay(alignment: .top) {
            if game.isLoading || game.isSaving {
                ProgressView()
                    .padding(8)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: Style.progressIndicatorCornerRadius)
                    )
                    .transition(.opacity)
            }
        }
        .animation(.default, value: game.isLoading)
        .animation(.default, value: game.isSaving)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if game.isSolved {
                Color.black.opacity(Style.overlayDimOpacity)
                    .ignoresSafeArea()
                
                Victory()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.5), value: game.isSolved)
        .onAppear {
            game.load()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(Game())
}
