//
//  ContentView.swift
//  sudoku
//

import SwiftUI

struct ContentView: View {
    @State private var game = Game()
    @State private var keyboardWidth: CGFloat?
    
    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.width < geo.size.height
            
            if isPortrait {
                VStack(spacing: 12) {
                    Header(game: game)
                    
                    PuzzleGrid(game: game)
                        .layoutPriority(1)
                    
                    Keyboard(game: game, isPortrait: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .bottom) {
                    PuzzleGrid(game: game)
                        .layoutPriority(1)
                    
                    VStack(spacing: 8) {
                        Header(game: game)
                            .frame(maxWidth: keyboardWidth)
                        Keyboard(game: game)
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
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity)
            }
        }
        .animation(.default, value: game.isLoading)
        .animation(.default, value: game.isSaving)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if game.isSolved {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                Victory(game: game)
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
}
