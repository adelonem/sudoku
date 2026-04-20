import Foundation
@testable import Sudoku

final class InMemoryDataStore: DataStore {
    private(set) var savedData: Data
    
    init(data: Data = Data()) {
        self.savedData = data
    }
    
    func load() throws -> Data {
        savedData
    }
    
    func save(_ data: Data) throws {
        savedData = data
    }
}
