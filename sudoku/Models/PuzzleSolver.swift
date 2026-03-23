//
//  PuzzleSolver.swift
//  sudoku
//

enum PuzzleSolver {
    /// Returns true if the cell at (`row`, `col`) has a digit that conflicts with another cell in the same row, column, or 3x3 block.
    static func hasConflict(atRow row: Int, col: Int, in puzzle: Puzzle) -> Bool {
        guard let digit = puzzle[row, col].digit else { return false }
        
        return Puzzle.peerIndices(ofRow: row, col: col).contains { index in
            puzzle.cells[index].digit == digit
        }
    }
    
    /// Returns the set of valid candidate digits (1-9) for the cell at (`row`, `col`) based on the current grid state.
    /// Returns an empty set if the cell already contains a digit.
    static func candidates(atRow row: Int, col: Int, in puzzle: Puzzle) -> Set<Int> {
        guard puzzle[row, col].digit == nil else { return [] }
        
        var possible = Set(1...Puzzle.size)
        for peer in Puzzle.peerIndices(ofRow: row, col: col) {
            if let digit = puzzle.cells[peer].digit {
                possible.remove(digit)
            }
        }
        return possible
    }
}
