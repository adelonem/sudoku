//
//  CellHighlight.swift
//  sudoku
//

/// The visual highlight state of a cell, ordered by display priority (highest first).
enum CellHighlight {
    case conflict
    case digitMatch
    case selected
    case peer
    case none
    
    /// Determines the highlight state for a cell based on the current game state.
    static func forCell(atRow row: Int, col: Int, selectedCell: CellPosition?, highlightedDigit: Int?, digit: Int?, hasConflict: Bool) -> CellHighlight {
        if hasConflict {
            return .conflict
        }
        if let highlightedDigit, let digit, highlightedDigit == digit {
            return .digitMatch
        }
        guard let selected = selectedCell else {
            return .none
        }
        if selected.row == row && selected.col == col {
            return .selected
        }
        let bs = Puzzle.blockSize
        if selected.row == row
            || selected.col == col
            || (selected.row / bs == row / bs && selected.col / bs == col / bs) {
            return .peer
        }
        return .none
    }
}
