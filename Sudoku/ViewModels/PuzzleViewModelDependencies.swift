import Foundation

@MainActor
struct PuzzleViewModelDependencies {
    let savedGameStore: any SavedGameStoring
    let completedPuzzleStore: any CompletedPuzzleStoring
    let catalogLoader: any PuzzleCatalogLoading
    let gameClock: any GameClock
    
    static var live: Self {
        Self(
            savedGameStore: SavedGameStore(dataStore: FileDataStore(fileName: "savedGame.json")),
            completedPuzzleStore: CompletedPuzzleStore(),
            catalogLoader: BundlePuzzleCatalogLoader(),
            gameClock: SystemGameClock()
        )
    }
}
