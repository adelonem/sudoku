//
//  PuzzleCatalog.swift
//  Sudoku
//

import Foundation

/// A collection of catalog entries decoded from a JSON data source, used to browse or pick a random puzzle.
struct PuzzleCatalog {
    let entries: [CatalogEntry]
    
    init(dataStore: DataStore) throws {
        let data = try dataStore.load()
        let decoded = try JSONDecoder().decode([CatalogEntry].self, from: data)
        guard !decoded.isEmpty else { throw PuzzleCatalogError.empty }
        self.entries = decoded
    }
    
    var count: Int {
        entries.count
    }
    
    func entry(at index: Int) -> CatalogEntry {
        entries[index]
    }
    
    func randomEntry() -> CatalogEntry {
        guard let entry = entries.randomElement() else {
            preconditionFailure("PuzzleCatalog must contain at least one entry")
        }
        return entry
    }
    
    func entry(byID id: Int) -> CatalogEntry? {
        entries.first { $0.id == id }
    }
    
    func entries(forDifficulty difficulty: String) -> [CatalogEntry] {
        entries.filter { $0.difficulty == difficulty }
    }
}
