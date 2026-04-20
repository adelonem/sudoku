//
//  PuzzleSolver.swift
//  Sudoku
//

import Foundation

enum PuzzleSolver {
    /// Pre-computed peer indices for every cell, indexed by `row * size + col`.
    /// Each entry contains the set of `(row, col)` pairs sharing a row, column, or block.
    private static let peerIndicesCache: [[(Int, Int)]] = {
        let size = Puzzle.size
        let bs = Puzzle.blockSize
        var cache: [[(Int, Int)]] = []
        cache.reserveCapacity(size * size)
        for row in 0..<size {
            for col in 0..<size {
                var result: Set<Int> = []
                let selfIndex = row * size + col
                
                for c in 0..<size { result.insert(row * size + c) }
                for r in 0..<size { result.insert(r * size + col) }
                
                let blockRow = (row / bs) * bs
                let blockCol = (col / bs) * bs
                for r in blockRow..<blockRow + bs {
                    for c in blockCol..<blockCol + bs {
                        result.insert(r * size + c)
                    }
                }
                
                result.remove(selfIndex)
                cache.append(result.map { ($0 / size, $0 % size) })
            }
        }
        return cache
    }()
    
    /// Returns the peer positions for a given cell.
    static func peerPositions(ofRow row: Int, col: Int) -> [(Int, Int)] {
        peerIndicesCache[row * Puzzle.size + col]
    }
    
    /// Returns true if the cell at (`row`, `col`) has a digit that conflicts with
    /// another cell in the same row, column, or 3×3 block.
    static func hasConflict(atRow row: Int, col: Int, in puzzle: Puzzle) -> Bool {
        guard let digit = puzzle.cells[row][col].value else { return false }
        return peerPositions(ofRow: row, col: col).contains { (r, c) in
            puzzle.cells[r][c].value == digit
        }
    }
    
    /// Returns the set of valid candidate digits (1–9) for the cell at (`row`, `col`).
    static func candidates(atRow row: Int, col: Int, in puzzle: Puzzle) -> Set<Int> {
        guard puzzle.cells[row][col].value == nil else { return [] }
        var possible = Set(1...Puzzle.size)
        for (r, c) in peerPositions(ofRow: row, col: col) {
            if let digit = puzzle.cells[r][c].value {
                possible.remove(digit)
            }
        }
        return possible
    }
    
    /// Returns true when the puzzle can be solved entirely by naked-single constraint
    /// propagation — i.e. every remaining empty cell has exactly one valid candidate,
    /// possibly after filling others in chain. No guessing required.
    static func isTrivial(_ puzzle: Puzzle) -> Bool {
        var cells = puzzle.cells
        var changed = true
        while changed {
            changed = false
            let tempPuzzle = Puzzle(cells: cells)
            for row in 0..<Puzzle.size {
                for col in 0..<Puzzle.size {
                    guard cells[row][col].value == nil else { continue }
                    let cands = candidates(atRow: row, col: col, in: tempPuzzle)
                    if cands.count == 1, let digit = cands.first {
                        cells[row][col] = .guess(digit)
                        changed = true
                    } else if cands.isEmpty {
                        return false  // contradiction
                    }
                }
            }
        }
        return cells.allSatisfy { row in row.allSatisfy { $0.value != nil } }
    }
    
    /// Solves the puzzle using backtracking with Minimum Remaining Values heuristic.
    /// Only considers `.fixed` cells as constraints.
    /// Returns the solved grid as an array of 81 digits, or nil if no solution exists.
    static func solve(_ puzzle: Puzzle) -> [Int]? {
        let size = Puzzle.size
        var grid = [Int](repeating: 0, count: size * size)
        for row in 0..<size {
            for col in 0..<size {
                if case .fixed(let d) = puzzle.cells[row][col] {
                    grid[row * size + col] = d
                }
            }
        }
        
        return backtrack(&grid) ? grid : nil
    }
    
    private static func backtrack(_ grid: inout [Int]) -> Bool {
        guard let cell = mrvCell(in: grid) else { return true }
        for digit in candidatesForIndex(cell, in: grid) {
            grid[cell] = digit
            if backtrack(&grid) { return true }
            grid[cell] = 0
        }
        return false
    }
    
    private static func mrvCell(in grid: [Int]) -> Int? {
        var bestIndex: Int?
        var bestCount = Int.max
        
        for i in 0..<grid.count where grid[i] == 0 {
            let count = candidatesForIndex(i, in: grid).count
            if count < bestCount {
                bestCount = count
                bestIndex = i
                if count == 1 { break }
            }
        }
        return bestIndex
    }
    
    private static func candidatesForIndex(_ index: Int, in grid: [Int]) -> Set<Int> {
        var possible = Set(1...Puzzle.size)
        let row = index / Puzzle.size
        let col = index % Puzzle.size
        for (r, c) in peerPositions(ofRow: row, col: col) {
            possible.remove(grid[r * Puzzle.size + c])
        }
        return possible
    }
}
