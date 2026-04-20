import Foundation
@testable import Sudoku

struct ReadOnlyInMemoryDataStore: DataStore {
    let data: Data
    
    func load() throws -> Data {
        data
    }
    
    func save(_ data: Data) throws {
        fatalError("Read-only data store")
    }
}
