import Testing
import Foundation
@testable import Sudoku

struct DataStoreErrorTests {
    
    @Test func resourceNotFoundIsError() {
        let error: Error = DataStoreError.resourceNotFound("test.json")
        #expect(error is DataStoreError)
    }
    
    @Test func resourceNotFoundCarriesName() {
        let error = DataStoreError.resourceNotFound("puzzles.json")
        if case .resourceNotFound(let name) = error {
            #expect(name == "puzzles.json")
        } else {
            Issue.record("Expected resourceNotFound")
        }
    }
}
