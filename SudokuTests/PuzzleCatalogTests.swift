import Testing
import Foundation
@testable import Sudoku

struct PuzzleCatalogTests {
    private static let entry1 = CatalogEntry(
        id: 1,
        difficulty: "easy",
        values: [
            [5, 3, 0, 0, 7, 0, 0, 0, 0],
            [6, 0, 0, 1, 9, 5, 0, 0, 0],
            [0, 9, 8, 0, 0, 0, 0, 6, 0],
            [8, 0, 0, 0, 6, 0, 0, 0, 3],
            [4, 0, 0, 8, 0, 3, 0, 0, 1],
            [7, 0, 0, 0, 2, 0, 0, 0, 6],
            [0, 6, 0, 0, 0, 0, 2, 8, 0],
            [0, 0, 0, 4, 1, 9, 0, 0, 5],
            [0, 0, 0, 0, 8, 0, 0, 7, 9]
        ],
        techniques: ["naked_singles"]
    )
    
    private static let entry2 = CatalogEntry(
        id: 2,
        difficulty: "medium",
        values: [
            [0, 0, 0, 2, 6, 0, 7, 0, 1],
            [6, 8, 0, 0, 7, 0, 0, 9, 0],
            [1, 9, 0, 0, 0, 4, 5, 0, 0],
            [8, 2, 0, 1, 0, 0, 0, 4, 0],
            [0, 0, 4, 6, 0, 2, 9, 0, 0],
            [0, 5, 0, 0, 0, 3, 0, 2, 8],
            [0, 0, 9, 3, 0, 0, 0, 7, 4],
            [0, 4, 0, 0, 5, 0, 0, 3, 6],
            [7, 0, 3, 0, 1, 8, 0, 0, 0]
        ],
        techniques: ["naked_singles", "hidden_singles"]
    )
    
    private static func dataStore(entries: [CatalogEntry]) throws -> ReadOnlyInMemoryDataStore {
        let data = try JSONEncoder().encode(entries)
        return ReadOnlyInMemoryDataStore(data: data)
    }
    
    @Test func countReturnsTotalEntries() throws {
        let catalog = try PuzzleCatalog(dataStore: Self.dataStore(entries: [Self.entry1, Self.entry2]))
        #expect(catalog.count == 2)
    }
    
    @Test func entryAtIndexReturnsCorrectEntry() throws {
        let catalog = try PuzzleCatalog(dataStore: Self.dataStore(entries: [Self.entry1, Self.entry2]))
        let first = catalog.entry(at: 0)
        #expect(first.id == 1)
        #expect(first.difficulty == "easy")
        #expect(first.puzzle.cells[0][0].value == 5)
        let second = catalog.entry(at: 1)
        #expect(second.id == 2)
        #expect(second.puzzle.cells[0][3].value == 2)
    }
    
    @Test func randomEntryReturnsValidEntry() throws {
        let catalog = try PuzzleCatalog(dataStore: Self.dataStore(entries: [Self.entry1, Self.entry2]))
        let entry = catalog.randomEntry()
        #expect(entry.puzzle.cells.count == 9)
        #expect(entry.puzzle.cells[0].count == 9)
    }
    
    @Test func entryByIDReturnsCorrectEntry() throws {
        let catalog = try PuzzleCatalog(dataStore: Self.dataStore(entries: [Self.entry1, Self.entry2]))
        let found = catalog.entry(byID: 2)
        #expect(found?.id == 2)
        #expect(found?.difficulty == "medium")
    }
    
    @Test func entryByIDReturnsNilForUnknownID() throws {
        let catalog = try PuzzleCatalog(dataStore: Self.dataStore(entries: [Self.entry1]))
        #expect(catalog.entry(byID: 99) == nil)
    }
    
    @Test func entriesForDifficultyFiltersCorrectly() throws {
        let catalog = try PuzzleCatalog(dataStore: Self.dataStore(entries: [Self.entry1, Self.entry2]))
        let easyEntries = catalog.entries(forDifficulty: "easy")
        #expect(easyEntries.count == 1)
        #expect(easyEntries[0].id == 1)
    }
    
    @Test func emptyCatalogThrows() throws {
        let dataStore = try Self.dataStore(entries: [])
        #expect(throws: PuzzleCatalogError.self) {
            try PuzzleCatalog(dataStore: dataStore)
        }
    }
}
