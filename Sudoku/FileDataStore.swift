//
//  FileDataStore.swift
//  Sudoku
//

import Foundation

/// Persists data as a file in the Application Support directory.
struct FileDataStore: DataStore {
    let fileName: String
    
    func load() throws -> Data {
        try Data(contentsOf: fileURL())
    }
    
    func save(_ data: Data) throws {
        try data.write(to: fileURL(), options: .atomic)
    }
    
    private func fileURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return directory.appending(path: fileName)
    }
}
