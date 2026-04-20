import Foundation
@testable import Sudoku

struct TestPuzzleCatalogLoader: PuzzleCatalogLoading {
    let result: Result<PuzzleCatalog, Error>
    
    init(result: Result<PuzzleCatalog, Error>) {
        self.result = result
    }
    
    func loadCatalog() throws -> PuzzleCatalog {
        try result.get()
    }
}
