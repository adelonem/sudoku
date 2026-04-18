//
//  SudokuTechnique.swift
//  Sudoku
//

import Foundation

/// A sudoku solving technique, identified by the snake_case key used in puzzles.json.
enum SudokuTechnique: String, CaseIterable {
    case nakedSingles    = "naked_singles"
    case hiddenSingles   = "hidden_singles"
    case nakedPairs      = "naked_pairs"
    case nakedTriples    = "naked_triples"
    case nakedQuads      = "naked_quads"
    case pointingPairs   = "pointing_pairs"
    case hiddenPairs     = "hidden_pairs"
    case hiddenTriples   = "hidden_triples"
    case hiddenQuads     = "hidden_quads"
    case xWing           = "x_wing"
    case skyscraper      = "skyscraper"
    case simpleColoring  = "simple_coloring"
    case uniqueRectangle = "unique_rectangle"
    case swordfish       = "swordfish"
    case jellyfish       = "jellyfish"
    case finnedXWing     = "finned_x_wing"
    case xyWing          = "xy_wing"
    case xyzWing         = "xyz_wing"
    case wxyzWing        = "wxyz_wing"
    case aic             = "aic"
    case forcingChains   = "forcing_chains"
    
    var title: String {
        switch self {
        case .nakedSingles:    String(localized: "Naked Single")
        case .hiddenSingles:   String(localized: "Hidden Single")
        case .nakedPairs:      String(localized: "Naked Pair")
        case .nakedTriples:    String(localized: "Naked Triple")
        case .nakedQuads:      String(localized: "Naked Quad")
        case .pointingPairs:   String(localized: "Pointing Pair")
        case .hiddenPairs:     String(localized: "Hidden Pair")
        case .hiddenTriples:   String(localized: "Hidden Triple")
        case .hiddenQuads:     String(localized: "Hidden Quad")
        case .xWing:           String(localized: "X-Wing")
        case .skyscraper:      String(localized: "Skyscraper")
        case .simpleColoring:  String(localized: "Simple Coloring")
        case .uniqueRectangle: String(localized: "Unique Rectangle")
        case .swordfish:       String(localized: "Swordfish")
        case .jellyfish:       String(localized: "Jellyfish")
        case .finnedXWing:     String(localized: "Finned X-Wing")
        case .xyWing:          String(localized: "XY-Wing")
        case .xyzWing:         String(localized: "XYZ-Wing")
        case .wxyzWing:        String(localized: "WXYZ-Wing")
        case .aic:             String(localized: "Alternating Inference Chain")
        case .forcingChains:   String(localized: "Forcing Chains")
        }
    }
    
    var difficulty: String {
        switch self {
        case .nakedSingles:
            String(localized: "Easy")
        case .hiddenSingles:
            String(localized: "Medium")
        case .nakedPairs,
                .nakedTriples,
                .nakedQuads,
                .pointingPairs:
            String(localized: "Hard")
        case .hiddenPairs,
                .hiddenTriples,
                .hiddenQuads,
                .xWing,
                .skyscraper,
                .simpleColoring,
                .uniqueRectangle:
            String(localized: "Expert")
        case .swordfish,
                .jellyfish,
                .finnedXWing,
                .xyWing,
                .xyzWing,
                .wxyzWing:
            String(localized: "Extreme")
        case .aic,
                .forcingChains:
            String(localized: "Diabolical")
        }
    }
}
