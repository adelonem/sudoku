import Testing
import Foundation
@testable import Sudoku

struct SavedGameStoreTests {
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
    
    @Test func saveAndLoadPreservesState() throws {
        let puzzle = Puzzle(values: Self.sampleGrid)
            .settingValue(4, row: 0, col: 2)
            .togglingNote(1, row: 1, col: 1)
            .togglingNote(2, row: 1, col: 1)
        
        let game = SavedGame(catalogID: 1, difficulty: "easy", techniques: ["naked_singles"], puzzle: puzzle, errorCount: 3, hintCount: 1, elapsedTime: 150)
        
        let dataStore = InMemoryDataStore()
        let storage = SavedGameStore(dataStore: dataStore)
        try storage.saveGame(game)
        
        let loaded = try storage.loadGame()
        
        #expect(loaded.catalogID == 1)
        #expect(loaded.difficulty == "easy")
        #expect(loaded.puzzle.cells[0][0].isFixed == true)
        #expect(loaded.puzzle.cells[0][0].value == 5)
        #expect(loaded.puzzle.cells[0][2].isGuess == true)
        #expect(loaded.puzzle.cells[0][2].value == 4)
        if case .notes(let candidates) = loaded.puzzle.cells[1][1] {
            #expect(candidates == [1, 2])
        } else {
            Issue.record("Expected .notes")
        }
    }
    
    @Test func loadGameFromInvalidDataThrows() {
        let dataStore = InMemoryDataStore(data: Data("not json".utf8))
        let storage = SavedGameStore(dataStore: dataStore)
        #expect(throws: DecodingError.self) {
            try storage.loadGame()
        }
    }
}
