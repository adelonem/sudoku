//
//  Cell.swift
//  sudoku
//

/// Represents the state of a single cell on the board.
enum Cell: Codable, Equatable {
    case empty
    case clue(Int)
    case userEntry(Int)
    case notes(Set<Int>)
    
    var digit: Int? {
        switch self {
        case .empty, .notes: return nil
        case .clue(let d), .userEntry(let d): return d
        }
    }
    
    var isClue: Bool {
        if case .clue = self { return true }
        return false
    }
    
    var cellNotes: Set<Int> {
        if case .notes(let n) = self { return n }
        return []
    }
}
