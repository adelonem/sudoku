import Testing
import Foundation
@testable import Sudoku

struct HintDetectorTests {
    
    // MARK: - Test data from puzzles.json
    
    /// Easy puzzle (id: 1) — solvable with naked_singles only
    private static let easyGrid: [[Int]] = [
        [0, 4, 0, 0, 8, 0, 2, 0, 3],
        [5, 8, 0, 7, 2, 0, 0, 0, 0],
        [0, 0, 3, 6, 0, 0, 0, 0, 7],
        [0, 2, 0, 5, 3, 9, 0, 1, 0],
        [8, 5, 1, 0, 0, 0, 0, 4, 0],
        [6, 3, 0, 4, 0, 8, 0, 0, 0],
        [0, 9, 0, 8, 7, 6, 0, 0, 2],
        [3, 7, 2, 9, 4, 1, 6, 5, 8],
        [1, 0, 0, 3, 5, 0, 0, 0, 0]
    ]
    
    /// Medium puzzle (id: 201) — requires hidden_singles
    private static let mediumGrid: [[Int]] = [
        [0, 6, 0, 4, 0, 5, 0, 7, 8],
        [0, 0, 0, 0, 1, 0, 0, 9, 4],
        [0, 8, 4, 0, 0, 0, 0, 0, 0],
        [0, 2, 3, 0, 7, 0, 4, 0, 0],
        [0, 0, 7, 0, 4, 3, 0, 5, 0],
        [0, 4, 0, 0, 2, 0, 0, 0, 0],
        [0, 0, 0, 0, 8, 2, 0, 0, 0],
        [2, 1, 8, 0, 0, 0, 3, 6, 0],
        [4, 3, 0, 6, 0, 1, 7, 0, 0]
    ]
    
    /// Hard puzzle (id: 501) — requires naked_pairs
    private static let hardGrid: [[Int]] = [
        [0, 5, 7, 0, 2, 3, 8, 0, 0],
        [0, 0, 0, 0, 0, 0, 5, 0, 0],
        [8, 0, 0, 9, 6, 5, 0, 0, 0],
        [0, 0, 0, 3, 1, 0, 0, 0, 4],
        [0, 2, 9, 8, 0, 0, 0, 5, 0],
        [0, 0, 0, 0, 0, 0, 0, 3, 0],
        [0, 0, 3, 0, 0, 8, 0, 6, 0],
        [0, 0, 8, 2, 0, 6, 0, 7, 0],
        [2, 6, 0, 0, 0, 7, 0, 0, 5]
    ]
    
    // MARK: - findHint
    
    @Test func findHintReturnsNakedSingleForEasyPuzzle() {
        let puzzle = Puzzle(values: Self.easyGrid)
        let hint = HintDetector.findHint(in: puzzle)
        #expect(hint != nil)
        #expect(hint?.technique == .nakedSingles)
        #expect(hint?.digit != nil)
        #expect(!hint!.primaryCells.isEmpty)
        #expect(!hint!.title.isEmpty)
        #expect(!hint!.explanation.isEmpty)
    }
    
    @Test func findHintReturnsValidPrimaryCell() {
        let puzzle = Puzzle(values: Self.easyGrid)
        guard let hint = HintDetector.findHint(in: puzzle) else {
            Issue.record("Expected a hint")
            return
        }
        let (row, col) = hint.primaryCells[0]
        #expect(row >= 0 && row < 9)
        #expect(col >= 0 && col < 9)
        #expect(puzzle.cells[row][col] == .empty)
    }
    
    @Test func findHintDigitIsValidCandidate() {
        let puzzle = Puzzle(values: Self.easyGrid)
        guard let hint = HintDetector.findHint(in: puzzle),
              let digit = hint.digit else {
            Issue.record("Expected a hint with digit")
            return
        }
        let (row, col) = hint.primaryCells[0]
        let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
        #expect(candidates.contains(digit))
    }
    
    @Test func findHintReturnsNilForSolvedPuzzle() {
        let puzzle = Puzzle(values: Self.easyGrid)
        guard let solution = PuzzleSolver.solve(puzzle) else {
            Issue.record("Expected a solution")
            return
        }
        var solved = puzzle
        for row in 0..<9 {
            for col in 0..<9 {
                if !solved.cells[row][col].isFixed {
                    solved = solved.settingValue(solution[row * 9 + col], row: row, col: col)
                }
            }
        }
        #expect(HintDetector.findHint(in: solved) == nil)
    }
    
    // MARK: - findHintChain
    
    @Test func findHintChainReturnsNonEmptyForEasyPuzzle() {
        let puzzle = Puzzle(values: Self.easyGrid)
        let chain = HintDetector.findHintChain(in: puzzle)
        #expect(!chain.isEmpty)
    }
    
    @Test func findHintChainEndsWithPlacementTechnique() {
        let puzzle = Puzzle(values: Self.easyGrid)
        let chain = HintDetector.findHintChain(in: puzzle)
        guard let last = chain.last else {
            Issue.record("Expected at least one hint in chain")
            return
        }
        let placementTechniques: Set<SudokuTechnique> = [.nakedSingles, .hiddenSingles]
        #expect(placementTechniques.contains(last.technique))
    }
    
    @Test func findHintChainForMediumPuzzle() {
        let puzzle = Puzzle(values: Self.mediumGrid)
        let chain = HintDetector.findHintChain(in: puzzle)
        #expect(!chain.isEmpty)
        let hint = chain[0]
        #expect(hint.digit != nil || !hint.primaryCells.isEmpty)
    }
    
    // MARK: - HintResult properties
    
    @Test func hintResultHasReasoning() {
        let puzzle = Puzzle(values: Self.easyGrid)
        guard let hint = HintDetector.findHint(in: puzzle) else {
            Issue.record("Expected a hint")
            return
        }
        #expect(!hint.reasoning.isEmpty)
    }
    
    @Test func hintResultTitleMatchesTechnique() {
        let puzzle = Puzzle(values: Self.easyGrid)
        guard let hint = HintDetector.findHint(in: puzzle) else {
            Issue.record("Expected a hint")
            return
        }
        #expect(hint.title == hint.technique.title)
    }
    
    // MARK: - Technique detection by difficulty
    
    @Test func hardPuzzleFindsHint() {
        let puzzle = Puzzle(values: Self.hardGrid)
        let hint = HintDetector.findHint(in: puzzle)
        #expect(hint != nil)
    }
    
    @Test func hardPuzzleChainMayIncludeAdvancedTechniques() {
        let puzzle = Puzzle(values: Self.hardGrid)
        let chain = HintDetector.findHintChain(in: puzzle)
        #expect(!chain.isEmpty)
        let techniques = Set(chain.map { $0.technique })
        #expect(!techniques.isEmpty)
    }
}
