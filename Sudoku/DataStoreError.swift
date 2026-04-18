//
//  DataStoreError.swift
//  Sudoku
//

import Foundation

/// Errors that can occur when loading or saving data through a ``DataStore``.
enum DataStoreError: Error {
    case resourceNotFound(String)
}
