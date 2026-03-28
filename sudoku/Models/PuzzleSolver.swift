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
    
    /// Solves the puzzle using a backtracking algorithm with Minimum Remaining Values (MRV) heuristic.
    /// Only considers `.clue` cells as constraints — all other cells are treated as empty.
    /// Returns the solved grid as an array of 81 digits, or nil if no solution exists.
    static func solve(_ puzzle: Puzzle) -> [Int]? {
        let size = Puzzle.size
        var grid = [Int](repeating: 0, count: size * size)
        
        // Seed the grid with clues only
        for i in 0..<grid.count {
            if case .clue(let d) = puzzle.cells[i] {
                grid[i] = d
            }
        }
        
        return backtrack(&grid) ? grid : nil
    }
    
    /// Recursive backtracking solver. Picks the empty cell with the fewest candidates (MRV) and tries each candidate in turn.
    private static func backtrack(_ grid: inout [Int]) -> Bool {
        // Find the empty cell with the minimum remaining values
        guard let cell = mrvCell(in: grid) else {
            return true // No empty cell left — puzzle is solved
        }
        
        for digit in candidatesForIndex(cell, in: grid) {
            grid[cell] = digit
            if backtrack(&grid) { return true }
            grid[cell] = 0
        }
        return false
    }
    
    /// Returns the index of the empty cell with the fewest remaining candidate values, or nil if every cell is filled.
    private static func mrvCell(in grid: [Int]) -> Int? {
        var bestIndex: Int?
        var bestCount = Int.max
        
        for i in 0..<grid.count where grid[i] == 0 {
            let count = candidatesForIndex(i, in: grid).count
            if count < bestCount {
                bestCount = count
                bestIndex = i
                if count == 1 { break } // Can't do better than 1
            }
        }
        return bestIndex
    }
    
    /// Returns the set of valid digits for a flat grid index, based on peer constraints.
    private static func candidatesForIndex(_ index: Int, in grid: [Int]) -> Set<Int> {
        var possible = Set(1...Puzzle.size)
        let row = index / Puzzle.size
        let col = index % Puzzle.size
        for peer in Puzzle.peerIndices(ofRow: row, col: col) {
            possible.remove(grid[peer])
        }
        return possible
    }
}
