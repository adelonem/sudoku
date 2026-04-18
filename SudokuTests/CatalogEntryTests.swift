import Testing
import Foundation
@testable import Sudoku

struct CatalogEntryTests {
    
    // MARK: - Test data from puzzles.json (id: 1, easy)
    
    private static let easyValues: [[Int]] = [
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
    
    private static let entry = CatalogEntry(
        id: 1,
        difficulty: "easy",
        values: easyValues,
        techniques: ["naked_singles"]
    )
    
    // MARK: - Properties
    
    @Test func propertiesAreCorrect() {
        #expect(Self.entry.id == 1)
        #expect(Self.entry.difficulty == "easy")
        #expect(Self.entry.techniques == ["naked_singles"])
        #expect(Self.entry.values.count == 9)
        #expect(Self.entry.values[0].count == 9)
    }
    
    // MARK: - Computed puzzle property
    
    @Test func puzzleConvertsFixedAndEmptyCells() {
        let puzzle = Self.entry.puzzle
        #expect(puzzle.cells.count == 9)
        // (0,1) = 4 → fixed
        #expect(puzzle.cells[0][1].isFixed == true)
        #expect(puzzle.cells[0][1].value == 4)
        // (0,0) = 0 → empty
        #expect(puzzle.cells[0][0] == .empty)
        // Row 7 is fully filled
        for col in 0..<9 {
            #expect(puzzle.cells[7][col].isFixed == true)
        }
    }
    
    @Test func puzzlePreservesAllValues() {
        let puzzle = Self.entry.puzzle
        for row in 0..<9 {
            for col in 0..<9 {
                let v = Self.easyValues[row][col]
                if v > 0 {
                    #expect(puzzle.cells[row][col].value == v)
                } else {
                    #expect(puzzle.cells[row][col] == .empty)
                }
            }
        }
    }
    
    // MARK: - Codable round-trip
    
    @Test func encodesAndDecodes() throws {
        let data = try JSONEncoder().encode(Self.entry)
        let decoded = try JSONDecoder().decode(CatalogEntry.self, from: data)
        #expect(decoded.id == Self.entry.id)
        #expect(decoded.difficulty == Self.entry.difficulty)
        #expect(decoded.techniques == Self.entry.techniques)
        #expect(decoded.values == Self.entry.values)
    }
    
    @Test func decodesFromJSON() throws {
        let json = """
        {
            "id": 42,
            "difficulty": "hard",
            "values": [
                [0,5,7,0,2,3,8,0,0],
                [0,0,0,0,0,0,5,0,0],
                [8,0,0,9,6,5,0,0,0],
                [0,0,0,3,1,0,0,0,4],
                [0,2,9,8,0,0,0,5,0],
                [0,0,0,0,0,0,0,3,0],
                [0,0,3,0,0,8,0,6,0],
                [0,0,8,2,0,6,0,7,0],
                [2,6,0,0,0,7,0,0,5]
            ],
            "techniques": ["naked_singles", "hidden_singles", "naked_pairs"]
        }
        """
        let decoded = try JSONDecoder().decode(CatalogEntry.self, from: Data(json.utf8))
        #expect(decoded.id == 42)
        #expect(decoded.difficulty == "hard")
        #expect(decoded.techniques.count == 3)
        #expect(decoded.puzzle.cells[0][1].value == 5)
        #expect(decoded.puzzle.cells[0][0] == .empty)
    }
    
    // MARK: - Multiple techniques
    
    @Test func multipleEntries() throws {
        let entries = [
            CatalogEntry(id: 1, difficulty: "easy", values: Self.easyValues, techniques: ["naked_singles"]),
            CatalogEntry(id: 2, difficulty: "medium", values: Self.easyValues, techniques: ["naked_singles", "hidden_singles"])
        ]
        let data = try JSONEncoder().encode(entries)
        let decoded = try JSONDecoder().decode([CatalogEntry].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].id == 1)
        #expect(decoded[1].techniques.count == 2)
    }
}
