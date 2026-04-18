//
//  BundleDataStore.swift
//  Sudoku
//

import Foundation

/// Loads data from a resource in the app's main bundle.
struct BundleDataStore: DataStore {
    let resource: String
    let withExtension: String
    
    func load() throws -> Data {
        guard let url = Bundle.main.url(forResource: resource, withExtension: withExtension) else {
            throw DataStoreError.resourceNotFound("\(resource).\(withExtension)")
        }
        return try Data(contentsOf: url)
    }
    
    func save(_ data: Data) throws {
        fatalError("BundleDataStore is read-only")
    }
}
