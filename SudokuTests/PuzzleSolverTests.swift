import Testing
import Foundation
@testable import Sudoku

struct PuzzleSolverTests {
    private static let sampleGrid: [[Int]] = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9]
    ]
    
    @Test func hasConflictReturnsFalseForEmptyCell() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        #expect(PuzzleSolver.hasConflict(atRow: 0, col: 2, in: puzzle) == false)
    }
    
    @Test func hasConflictReturnsFalseForValidClue() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        #expect(PuzzleSolver.hasConflict(atRow: 0, col: 0, in: puzzle) == false)
    }
    
    @Test func hasConflictReturnsTrueForRowConflict() {
        let puzzle = Puzzle(values: Self.sampleGrid)
            .settingValue(5, row: 0, col: 2)
        #expect(PuzzleSolver.hasConflict(atRow: 0, col: 2, in: puzzle) == true)
    }
    
    @Test func hasConflictReturnsTrueForColumnConflict() {
        let puzzle = Puzzle(values: Self.sampleGrid)
            .settingValue(5, row: 2, col: 0)
        #expect(PuzzleSolver.hasConflict(atRow: 2, col: 0, in: puzzle) == true)
    }
    
    @Test func hasConflictReturnsTrueForBlockConflict() {
        let puzzle = Puzzle(values: Self.sampleGrid)
            .settingValue(5, row: 1, col: 1)
        #expect(PuzzleSolver.hasConflict(atRow: 1, col: 1, in: puzzle) == true)
    }
    
    @Test func hasConflictReturnsFalseForValidGuess() {
        let puzzle = Puzzle(values: Self.sampleGrid)
            .settingValue(4, row: 0, col: 2)
        #expect(PuzzleSolver.hasConflict(atRow: 0, col: 2, in: puzzle) == false)
    }
    
    @Test func candidatesReturnsEmptyForFilledCell() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        #expect(PuzzleSolver.candidates(atRow: 0, col: 0, in: puzzle).isEmpty)
    }
    
    @Test func candidatesExcludesRowColumnAndBlockDigits() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        let result = PuzzleSolver.candidates(atRow: 0, col: 2, in: puzzle)
        #expect(result == [1, 2, 4])
    }
    
    @Test func candidatesForCellWithManyCandidates() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        let result = PuzzleSolver.candidates(atRow: 4, col: 4, in: puzzle)
        #expect(result == [5])
    }
    
    @Test func solveReturnsValidSolution() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        let solution = PuzzleSolver.solve(puzzle)
        #expect(solution != nil)
        #expect(solution?.count == 81)
        if let sol = solution {
            #expect(sol.allSatisfy { $0 >= 1 && $0 <= 9 })
        }
    }
    
    @Test func solutionPreservesClues() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        guard let solution = PuzzleSolver.solve(puzzle) else {
            Issue.record("Expected a solution")
            return
        }
        
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                if Self.sampleGrid[row][col] > 0 {
                    #expect(solution[row * Puzzle.size + col] == Self.sampleGrid[row][col])
                }
            }
        }
    }
    
    @Test func solutionHasNoConflicts() {
        let puzzle = Puzzle(values: Self.sampleGrid)
        guard let solution = PuzzleSolver.solve(puzzle) else {
            Issue.record("Expected a solution")
            return
        }
        
        var solved = puzzle
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                if !solved.cells[row][col].isFixed {
                    solved = solved.settingValue(solution[row * Puzzle.size + col], row: row, col: col)
                }
            }
        }
        
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                #expect(PuzzleSolver.hasConflict(atRow: row, col: col, in: solved) == false)
            }
        }
    }
    
    @Test func solveReturnsNilForUnsolvablePuzzle() {
        var grid = Self.sampleGrid
        grid[0][2] = 5
        let puzzle = Puzzle(values: grid)
        #expect(PuzzleSolver.solve(puzzle) == nil)
    }
}
