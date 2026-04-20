import Foundation

protocol PuzzleCatalogLoading {
    func loadCatalog() throws -> PuzzleCatalog
}

struct BundlePuzzleCatalogLoader: PuzzleCatalogLoading {
    private let dataStore: DataStore
    
    init(dataStore: DataStore = BundleDataStore(resource: "puzzles", withExtension: "json")) {
        self.dataStore = dataStore
    }
    
    func loadCatalog() throws -> PuzzleCatalog {
        try PuzzleCatalog(dataStore: dataStore)
    }
}
