//
//  Main.swift
//  sudoku
//

import SwiftUI

@main
struct Main: App {
    @State private var game = Game()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
        }
    }
}
