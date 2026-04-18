//
//  DataStore.swift
//  Sudoku
//

import Foundation

/// Abstracts raw data persistence, enabling dependency injection and testability.
protocol DataStore {
    func load() throws -> Data
    func save(_ data: Data) throws
}
