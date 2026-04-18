//
//  LocalizedDifficulty.swift
//  Sudoku
//

import Foundation

/// Maps a raw difficulty key from JSON (e.g., "easy") to a localized display string.
func localizedDifficulty(_ rawValue: String) -> String {
    switch rawValue.lowercased() {
    case "easy":       String(localized: "Easy")
    case "medium":     String(localized: "Medium")
    case "hard":       String(localized: "Hard")
    case "expert":     String(localized: "Expert")
    case "extreme":    String(localized: "Extreme")
    case "diabolical": String(localized: "Diabolical")
    default:           rawValue.capitalized
    }
}
