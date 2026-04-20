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
    
    private static let diabolicalSavedGameJSON = #"""
    {"errorCount":1,"catalogID":3177,"techniques":["hidden_singles","naked_singles","naked_pairs","naked_triples","pointing_pairs","forcing_chains"],"difficulty":"diabolic","puzzle":{"cells":[[{"type":"empty"},{"type":"empty"},{"type":"empty"},{"value":7,"type":"fixed"},{"type":"empty"},{"value":3,"type":"fixed"},{"value":6,"type":"guess"},{"type":"empty"},{"type":"empty"}],[{"value":6,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"value":5,"type":"guess"},{"type":"empty"},{"value":4,"type":"guess"},{"type":"empty"},{"value":8,"type":"fixed"},{"type":"empty"}],[{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"},{"value":6,"type":"guess"},{"type":"empty"},{"value":1,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"type":"empty"}],[{"value":9,"type":"guess"},{"value":6,"type":"fixed"},{"value":4,"type":"fixed"},{"value":1,"type":"guess"},{"value":3,"type":"guess"},{"value":2,"type":"guess"},{"value":8,"type":"guess"},{"type":"empty"},{"type":"empty"}],[{"value":2,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"type":"empty"},{"value":5,"type":"guess"},{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"},{"value":3,"type":"fixed"}],[{"type":"empty"},{"value":5,"type":"fixed"},{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"value":1,"type":"fixed"},{"value":2,"type":"fixed"},{"type":"empty"}],[{"type":"empty"},{"type":"empty"},{"value":9,"type":"guess"},{"type":"empty"},{"type":"empty"},{"value":5,"type":"fixed"},{"value":2,"type":"fixed"},{"type":"empty"},{"type":"empty"}],[{"type":"empty"},{"value":7,"type":"fixed"},{"value":2,"type":"guess"},{"value":3,"type":"fixed"},{"value":6,"type":"fixed"},{"value":9,"type":"guess"},{"type":"empty"},{"type":"empty"},{"value":8,"type":"fixed"}],[{"type":"empty"},{"type":"empty"},{"value":6,"type":"guess"},{"value":2,"type":"guess"},{"value":1,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"}]]},"elapsedTime":128,"hintCount":0}
    """#
    
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
    
    @MainActor
    @Test func diabolicalSavedGameChainEndsWithForcingChainPlacement() throws {
        let savedGame = try JSONDecoder().decode(SavedGame.self, from: Data(Self.diabolicalSavedGameJSON.utf8))
        let chain = HintDetector.findHintChain(in: savedGame.puzzle)
        
        #expect(!chain.isEmpty)
        #expect(chain.count >= 2)
        guard chain.count >= 2 else {
            Issue.record("Expected a forcing chain step followed by a placement")
            return
        }
        
        let contradictionStep = chain[chain.count - 2]
        let placementStep = chain[chain.count - 1]
        
        #expect(contradictionStep.technique == .forcingChains)
        #expect(contradictionStep.digit == 3)
        #expect(contradictionStep.secondaryCells.count == 1)
        #expect(contradictionStep.secondaryCells[0].row == 1)
        #expect(contradictionStep.secondaryCells[0].col == 6)
        #expect(contradictionStep.eliminations.count == 1)
        #expect(contradictionStep.eliminations[0].row == 1)
        #expect(contradictionStep.eliminations[0].col == 6)
        #expect(contradictionStep.eliminations[0].digit == 3)
        
        #expect(placementStep.technique == .nakedSingles)
        #expect(placementStep.digit == 7)
        #expect(placementStep.primaryCells.count == 1)
        #expect(placementStep.primaryCells[0].row == 1)
        #expect(placementStep.primaryCells[0].col == 6)
    }
}
