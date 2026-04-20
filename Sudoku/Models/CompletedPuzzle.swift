//
//  CompletedPuzzle.swift
//  Sudoku
//

import Foundation

/// A record of a puzzle the player has completed during active play.
struct CompletedPuzzle: Codable, Identifiable {
    let catalogID: Int
    let difficulty: String
    let completedAt: Date
    let errorCount: Int
    let hintCount: Int
    let elapsedTime: TimeInterval
    
    var id: Int { catalogID }
}
