//
//  CatalogEntry.swift
//  Sudoku
//

import Foundation

/// A single entry in the puzzle catalog, pairing a grid with its metadata.
struct CatalogEntry: Codable {
    let id: Int
    let difficulty: String
    let values: [[Int]]
    let techniques: [String]
    
    var puzzle: Puzzle {
        Puzzle(values: values)
    }
}
