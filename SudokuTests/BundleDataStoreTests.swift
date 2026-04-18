import Testing
import Foundation
@testable import Sudoku

struct BundleDataStoreTests {
    
    @Test func loadMissingResourceThrowsResourceNotFound() {
        let store = BundleDataStore(resource: "nonexistent_resource", withExtension: "json")
        #expect(throws: DataStoreError.self) {
            try store.load()
        }
    }
    
    @Test func loadMissingResourceErrorMessage() {
        let store = BundleDataStore(resource: "missing", withExtension: "txt")
        do {
            _ = try store.load()
            Issue.record("Expected an error")
        } catch let error as DataStoreError {
            if case .resourceNotFound(let name) = error {
                #expect(name == "missing.txt")
            } else {
                Issue.record("Expected resourceNotFound error")
            }
        } catch {
            Issue.record("Expected DataStoreError")
        }
    }
}
