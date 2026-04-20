import Foundation

protocol SavedGameStoring {
    func loadGame() throws -> SavedGame
    func saveGame(_ game: SavedGame) throws
}

struct SavedGameStore: SavedGameStoring {
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
