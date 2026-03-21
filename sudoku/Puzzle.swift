//
//  Puzzle.swift
//  sudoku
//

import Foundation

/// Represents the state of a single cell on the board.
enum Cell: Codable, Equatable {
    case empty
    case clue(Int)
    case userEntry(Int)

    var digit: Int? {
        switch self {
        case .empty: return nil
        case .clue(let d), .userEntry(let d): return d
        }
    }

    var isClue: Bool {
        if case .clue = self { return true }
        return false
    }
}

struct Puzzle: Codable {
    var cells: [Cell]

    init() {
        cells = Array(repeating: .empty, count: 81)
    }

    subscript(row: Int, col: Int) -> Cell {
        get { cells[row * 9 + col] }
        set { cells[row * 9 + col] = newValue }
    }
}
