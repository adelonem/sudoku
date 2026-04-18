import Testing
import Foundation
@testable import Sudoku

struct PuzzleTests {
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
    
    @Test func initCreatesFixedAndEmptyCells() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
        #expect(puzzle.cells[0][0].isFixed == true)
        #expect(puzzle.cells[0][0].value == 5)
        #expect(puzzle.cells[0][2] == .empty)
    }
    
    @Test func setValueOnEmptyCell() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .settingValue(4, row: 0, col: 2)
        #expect(puzzle.cells[0][2].isGuess == true)
        #expect(puzzle.cells[0][2].value == 4)
    }
    
    @Test func setValueOnFixedCellDoesNothing() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .settingValue(1, row: 0, col: 0)
        #expect(puzzle.cells[0][0].value == 5)
        #expect(puzzle.cells[0][0].isFixed == true)
    }
    
    @Test func toggleNoteAddsNote() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .togglingNote(4, row: 0, col: 2)
        if case .notes(let candidates) = puzzle.cells[0][2] {
            #expect(candidates == [4])
        } else {
            Issue.record("Expected .notes")
        }
    }
    
    @Test func toggleNoteRemovesExistingNote() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .togglingNote(4, row: 0, col: 2)
            .togglingNote(4, row: 0, col: 2)
        #expect(puzzle.cells[0][2] == .empty)
    }
    
    @Test func toggleNoteOnFixedCellDoesNothing() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .togglingNote(1, row: 0, col: 0)
        #expect(puzzle.cells[0][0].isFixed == true)
    }
    
    @Test func toggleNoteOnGuessCellDoesNothing() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .settingValue(4, row: 0, col: 2)
            .togglingNote(1, row: 0, col: 2)
        #expect(puzzle.cells[0][2].isGuess == true)
        #expect(puzzle.cells[0][2].value == 4)
    }
    
    @Test func clearCellResetsToEmpty() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .settingValue(4, row: 0, col: 2)
            .clearingCell(row: 0, col: 2)
        #expect(puzzle.cells[0][2] == .empty)
    }
    
    @Test func clearCellOnFixedDoesNothing() {
        let puzzle = Puzzle(values: PuzzleTests.sampleGrid)
            .clearingCell(row: 0, col: 0)
        #expect(puzzle.cells[0][0].isFixed == true)
        #expect(puzzle.cells[0][0].value == 5)
    }
}
