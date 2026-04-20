import Foundation
@testable import Sudoku

final class TestSavedGameStore: SavedGameStoring {
    private(set) var savedGames: [SavedGame] = []
    var loadResult: Result<SavedGame, Error>
    
    init(loadResult: Result<SavedGame, Error> = .failure(TestDoubleError.unavailable)) {
        self.loadResult = loadResult
    }
    
    func loadGame() throws -> SavedGame {
        try loadResult.get()
    }
    
    func saveGame(_ game: SavedGame) throws {
        savedGames.append(game)
        loadResult = .success(game)
    }
}
