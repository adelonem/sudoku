import Testing
import Foundation
@testable import Sudoku

struct CompletedPuzzleTests {
    
    // MARK: - Properties
    
    @Test func propertiesAreCorrect() {
        let date = Date()
        let puzzle = CompletedPuzzle(
            catalogID: 5,
            difficulty: "medium",
            completedAt: date,
            errorCount: 2,
            hintCount: 1,
            elapsedTime: 305.5
        )
        #expect(puzzle.catalogID == 5)
        #expect(puzzle.difficulty == "medium")
        #expect(puzzle.completedAt == date)
        #expect(puzzle.errorCount == 2)
        #expect(puzzle.hintCount == 1)
        #expect(puzzle.elapsedTime == 305.5)
    }
    
    // MARK: - Identifiable
    
    @Test func idEqualsCatalogID() {
        let puzzle = CompletedPuzzle(
            catalogID: 42,
            difficulty: "hard",
            completedAt: Date(),
            errorCount: 0,
            hintCount: 0,
            elapsedTime: 120
        )
        #expect(puzzle.id == 42)
        #expect(puzzle.id == puzzle.catalogID)
    }
    
    // MARK: - Codable round-trip
    
    @Test func encodesAndDecodes() throws {
        let original = CompletedPuzzle(
            catalogID: 10,
            difficulty: "expert",
            completedAt: Date(timeIntervalSince1970: 1700000000),
            errorCount: 3,
            hintCount: 2,
            elapsedTime: 600
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CompletedPuzzle.self, from: data)
        #expect(decoded.catalogID == original.catalogID)
        #expect(decoded.difficulty == original.difficulty)
        #expect(decoded.completedAt == original.completedAt)
        #expect(decoded.errorCount == original.errorCount)
        #expect(decoded.hintCount == original.hintCount)
        #expect(decoded.elapsedTime == original.elapsedTime)
    }
    
    @Test func encodesAndDecodesArray() throws {
        let puzzles = [
            CompletedPuzzle(catalogID: 1, difficulty: "easy", completedAt: Date(), errorCount: 0, hintCount: 0, elapsedTime: 60),
            CompletedPuzzle(catalogID: 2, difficulty: "medium", completedAt: Date(), errorCount: 1, hintCount: 0, elapsedTime: 180)
        ]
        let data = try JSONEncoder().encode(puzzles)
        let decoded = try JSONDecoder().decode([CompletedPuzzle].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].catalogID == 1)
        #expect(decoded[1].catalogID == 2)
    }
    
    @Test func zeroValuesAreValid() throws {
        let puzzle = CompletedPuzzle(
            catalogID: 1,
            difficulty: "easy",
            completedAt: Date(),
            errorCount: 0,
            hintCount: 0,
            elapsedTime: 0
        )
        let data = try JSONEncoder().encode(puzzle)
        let decoded = try JSONDecoder().decode(CompletedPuzzle.self, from: data)
        #expect(decoded.errorCount == 0)
        #expect(decoded.hintCount == 0)
        #expect(decoded.elapsedTime == 0)
    }
}
