import Testing
import Foundation
@testable import Sudoku

struct PuzzleCatalogErrorTests {
    
    @Test func emptyIsError() {
        let error: Error = PuzzleCatalogError.empty
        #expect(error is PuzzleCatalogError)
    }
}
