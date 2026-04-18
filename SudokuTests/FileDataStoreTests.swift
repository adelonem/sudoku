import Testing
import Foundation
@testable import Sudoku

struct FileDataStoreTests {
    
    @Test func saveAndLoadRoundTrip() throws {
        let fileName = "test_\(UUID().uuidString).json"
        let store = FileDataStore(fileName: fileName)
        let original = Data("hello world".utf8)
        
        try store.save(original)
        let loaded = try store.load()
        #expect(loaded == original)
        
        let dir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        try? FileManager.default.removeItem(at: dir.appending(path: fileName))
    }
    
    @Test func saveAndLoadJSON() throws {
        let fileName = "test_\(UUID().uuidString).json"
        let store = FileDataStore(fileName: fileName)
        let entry = CatalogEntry(
            id: 1,
            difficulty: "easy",
            values: [[1,2,3,4,5,6,7,8,9]],
            techniques: ["naked_singles"]
        )
        let data = try JSONEncoder().encode(entry)
        try store.save(data)
        
        let loaded = try store.load()
        let decoded = try JSONDecoder().decode(CatalogEntry.self, from: loaded)
        #expect(decoded.id == 1)
        
        let dir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        try? FileManager.default.removeItem(at: dir.appending(path: fileName))
    }
    
    @Test func loadNonExistentFileThrows() {
        let store = FileDataStore(fileName: "nonexistent_\(UUID().uuidString).json")
        #expect(throws: Error.self) {
            try store.load()
        }
    }
    
    @Test func overwriteExistingFile() throws {
        let fileName = "test_\(UUID().uuidString).json"
        let store = FileDataStore(fileName: fileName)
        
        try store.save(Data("first".utf8))
        try store.save(Data("second".utf8))
        let loaded = try store.load()
        #expect(String(data: loaded, encoding: .utf8) == "second")
        
        let dir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        try? FileManager.default.removeItem(at: dir.appending(path: fileName))
    }
}
