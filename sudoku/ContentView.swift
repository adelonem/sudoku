//
//  ContentView.swift
//  sudoku
//

import SwiftUI

struct ContentView: View {
    @State private var game = Game()

    var body: some View {
        HStack(alignment: .bottom) {
            GridView(game: game)
                .layoutPriority(1)

            KeyboardView(game: game)
        }
        .onAppear {
            game.load()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
