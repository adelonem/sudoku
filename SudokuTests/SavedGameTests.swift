import Testing
import Foundation
@testable import Sudoku

struct SavedGameTests {
    
    // MARK: - Test data from puzzles.json (id: 1, easy)
    
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
    
    // MARK: - Properties
    
    @Test func propertiesAreCorrect() {
        let puzzle = Puzzle(values: Self.easyGrid)
        let game = SavedGame(
            catalogID: 1,
            difficulty: "easy",
            techniques: ["naked_singles"],
            puzzle: puzzle,
            errorCount: 2,
            hintCount: 1,
            elapsedTime: 150.5
        )
        #expect(game.catalogID == 1)
        #expect(game.difficulty == "easy")
        #expect(game.techniques == ["naked_singles"])
        #expect(game.errorCount == 2)
        #expect(game.hintCount == 1)
        #expect(game.elapsedTime == 150.5)
    }
    
    // MARK: - Codable round-trip
    
    @Test func encodesAndDecodesBasicState() throws {
        let puzzle = Puzzle(values: Self.easyGrid)
        let original = SavedGame(
            catalogID: 1,
            difficulty: "easy",
            techniques: ["naked_singles"],
            puzzle: puzzle,
            errorCount: 0,
            hintCount: 0,
            elapsedTime: 0
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SavedGame.self, from: data)
        #expect(decoded.catalogID == 1)
        #expect(decoded.difficulty == "easy")
        #expect(decoded.techniques == ["naked_singles"])
        #expect(decoded.puzzle.cells[0][1].isFixed == true)
        #expect(decoded.puzzle.cells[0][1].value == 4)
        #expect(decoded.puzzle.cells[0][0] == .empty)
    }
    
    @Test func encodesAndDecodesWithGuesses() throws {
        let puzzle = Puzzle(values: Self.easyGrid)
            .settingValue(7, row: 0, col: 0)
            .settingValue(9, row: 0, col: 2)
        let original = SavedGame(
            catalogID: 1,
            difficulty: "easy",
            techniques: ["naked_singles"],
            puzzle: puzzle,
            errorCount: 1,
            hintCount: 0,
            elapsedTime: 45
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SavedGame.self, from: data)
        #expect(decoded.puzzle.cells[0][0].isGuess == true)
        #expect(decoded.puzzle.cells[0][0].value == 7)
        #expect(decoded.puzzle.cells[0][2].isGuess == true)
        #expect(decoded.puzzle.cells[0][2].value == 9)
        #expect(decoded.errorCount == 1)
    }
    
    @Test func encodesAndDecodesWithNotes() throws {
        let puzzle = Puzzle(values: Self.easyGrid)
            .togglingNote(7, row: 0, col: 0)
            .togglingNote(9, row: 0, col: 0)
        let original = SavedGame(
            catalogID: 1,
            difficulty: "easy",
            techniques: ["naked_singles"],
            puzzle: puzzle,
            errorCount: 0,
            hintCount: 0,
            elapsedTime: 30
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SavedGame.self, from: data)
        if case .notes(let candidates) = decoded.puzzle.cells[0][0] {
            #expect(candidates == [7, 9])
        } else {
            Issue.record("Expected .notes")
        }
    }
    
    @Test func encodesAndDecodesWithMultipleTechniques() throws {
        let puzzle = Puzzle(values: Self.easyGrid)
        let original = SavedGame(
            catalogID: 501,
            difficulty: "hard",
            techniques: ["naked_singles", "hidden_singles", "naked_pairs"],
            puzzle: puzzle,
            errorCount: 5,
            hintCount: 3,
            elapsedTime: 900
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SavedGame.self, from: data)
        #expect(decoded.catalogID == 501)
        #expect(decoded.difficulty == "hard")
        #expect(decoded.techniques.count == 3)
        #expect(decoded.techniques.contains("naked_pairs"))
    }
}
