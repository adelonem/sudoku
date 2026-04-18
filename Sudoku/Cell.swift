//
//  Cell.swift
//  Sudoku
//

import Foundation

/// A single cell in a Sudoku grid: either a fixed clue, a player's guess, pencil-mark notes, or an empty cell.
enum Cell: Equatable, Sendable {
    case fixed(Int)
    case guess(Int)
    case notes(Set<Int>)
    case empty
}

extension Cell {
    var isFixed: Bool {
        if case .fixed = self { return true }
        return false
    }
    
    var isGuess: Bool {
        if case .guess = self { return true }
        return false
    }
    
    var notes: Set<Int> {
        if case .notes(let candidates) = self { return candidates }
        return []
    }
    
    var value: Int? {
        switch self {
        case .fixed(let v), .guess(let v): return v
        default: return nil
        }
    }
}

extension Cell: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, value, notes
    }
    
    private enum CellType: String, Codable {
        case fixed, guess, notes, empty
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixed(let v):
            try container.encode(CellType.fixed, forKey: .type)
            try container.encode(v, forKey: .value)
        case .guess(let v):
            try container.encode(CellType.guess, forKey: .type)
            try container.encode(v, forKey: .value)
        case .notes(let candidates):
            try container.encode(CellType.notes, forKey: .type)
            try container.encode(candidates.sorted(), forKey: .notes)
        case .empty:
            try container.encode(CellType.empty, forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CellType.self, forKey: .type)
        switch type {
        case .fixed:
            self = .fixed(try container.decode(Int.self, forKey: .value))
        case .guess:
            self = .guess(try container.decode(Int.self, forKey: .value))
        case .notes:
            let candidates = try container.decode([Int].self, forKey: .notes)
            self = .notes(Set(candidates))
        case .empty:
            self = .empty
        }
    }
}
