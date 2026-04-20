//
//  SavedGame.swift
//  Sudoku
//

import Foundation

/// Snapshot of a game in progress, preserving catalog metadata alongside the current puzzle state.
struct SavedGame: Codable {
    let catalogID: Int
    let difficulty: String
    let techniques: [String]
    let puzzle: Puzzle
    let errorCount: Int
    let hintCount: Int
    let elapsedTime: TimeInterval
}
