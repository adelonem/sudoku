import Testing
import Foundation
@testable import Sudoku

struct CompletedPuzzleStoreTests {
    
    @Test func loadAllReturnsEmptyWhenNoData() {
        let dataStore = InMemoryDataStore()
        let store = CompletedPuzzleStore(dataStore: dataStore)
        #expect(store.loadAll().isEmpty)
    }
    
    @Test func recordCompletionPersistsEntry() {
        let dataStore = InMemoryDataStore()
        let store = CompletedPuzzleStore(dataStore: dataStore)
        
        store.recordCompletion(catalogID: 5, difficulty: "easy", errorCount: 2, hintCount: 0, elapsedTime: 120)
        
        let entries = store.loadAll()
        #expect(entries.count == 1)
        #expect(entries[0].catalogID == 5)
        #expect(entries[0].difficulty == "easy")
        #expect(entries[0].errorCount == 2)
    }
    
    @Test func duplicatePuzzleKeepsOnlyLatest() {
        let dataStore = InMemoryDataStore()
        let store = CompletedPuzzleStore(dataStore: dataStore)
        
        store.recordCompletion(catalogID: 3, difficulty: "medium", errorCount: 0, hintCount: 0, elapsedTime: 60)
        let firstDate = store.loadAll()[0].completedAt
        
        store.recordCompletion(catalogID: 3, difficulty: "medium", errorCount: 1, hintCount: 0, elapsedTime: 90)
        let entries = store.loadAll()
        
        #expect(entries.count == 1)
        #expect(entries[0].completedAt >= firstDate)
    }
    
    @Test func entriesAreSortedByCatalogID() {
        let dataStore = InMemoryDataStore()
        let store = CompletedPuzzleStore(dataStore: dataStore)
        
        store.recordCompletion(catalogID: 10, difficulty: "hard", errorCount: 0, hintCount: 0, elapsedTime: 300)
        store.recordCompletion(catalogID: 2, difficulty: "easy", errorCount: 3, hintCount: 0, elapsedTime: 45)
        store.recordCompletion(catalogID: 7, difficulty: "medium", errorCount: 1, hintCount: 0, elapsedTime: 180)
        
        let entries = store.loadAll()
        #expect(entries.count == 3)
        #expect(entries[0].catalogID == 2)
        #expect(entries[1].catalogID == 7)
        #expect(entries[2].catalogID == 10)
    }
    
    @Test func loadAllReturnsEmptyForInvalidData() {
        let dataStore = InMemoryDataStore(data: Data("not json".utf8))
        let store = CompletedPuzzleStore(dataStore: dataStore)
        #expect(store.loadAll().isEmpty)
    }
}
