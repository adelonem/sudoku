//
//  GameStorage.swift
//  Sudoku
//

import Foundation

/// Encodes and decodes a ``SavedGame`` to and from persistent storage via a ``DataStore``.
struct GameStore {
    let dataStore: DataStore
    
    func loadGame() throws -> SavedGame {
        let data = try dataStore.load()
        return try JSONDecoder().decode(SavedGame.self, from: data)
    }
    
    func saveGame(_ game: SavedGame) throws {
        let data = try JSONEncoder().encode(game)
        try dataStore.save(data)
    }
}
