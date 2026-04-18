//
//  CompletedPuzzlesStore.swift
//  Sudoku
//

import Foundation

/// Persists the list of puzzles completed by the player.
/// Each puzzle appears at most once — only the latest completion is kept.
struct CompletedPuzzlesStore {
    private let dataStore: DataStore
    
    init(dataStore: DataStore = FileDataStore(fileName: "completedPuzzles.json")) {
        self.dataStore = dataStore
    }
    
    func loadAll() -> [CompletedPuzzle] {
        guard let data = try? dataStore.load(),
              let entries = try? JSONDecoder().decode([CompletedPuzzle].self, from: data) else {
            return []
        }
        return entries.sorted { $0.catalogID < $1.catalogID }
    }
    
    func recordCompletion(catalogID: Int, difficulty: String, errorCount: Int, hintCount: Int, elapsedTime: TimeInterval) {
        var entries = loadAll()
        entries.removeAll { $0.catalogID == catalogID }
        entries.append(CompletedPuzzle(catalogID: catalogID, difficulty: difficulty, completedAt: Date(), errorCount: errorCount, hintCount: hintCount, elapsedTime: elapsedTime))
        entries.sort { $0.catalogID < $1.catalogID }
        if let data = try? JSONEncoder().encode(entries) {
            try? dataStore.save(data)
        }
    }
}
