//
//  Storage.swift
//  sudoku
//

import Foundation

enum Storage {
    private struct RawPuzzle: Decodable {
        let number: Int?
        let difficulty: String?
        let puzzle: [Int?]
    }
    
    /// Loads the puzzle collection from the bundled puzzles.json file (synchronous, bundle access).
    static func loadPuzzleCollection() -> [Puzzle]? {
        guard let url = Bundle.main.url(forResource: "puzzles", withExtension: "json") else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([RawPuzzle].self, from: data)
            return raw.map { entry in
                var puzzle = Puzzle()
                puzzle.number = entry.number
                puzzle.difficulty = entry.difficulty
                puzzle.cells = entry.puzzle.map { value in
                    guard let value else { return .empty }
                    return .clue(value)
                }
                return puzzle
            }
        } catch {
            print(error)
            return nil
        }
    }
    
    /// Loads the saved game from Application Support asynchronously.
    static func load() async -> Puzzle? {
        guard let url = savedPuzzleURL() else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Puzzle.self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    
    /// Saves the current game to Application Support asynchronously.
    static func save(_ puzzle: Puzzle) async {
        guard let url = savedPuzzleURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(puzzle)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
    
    /// Returns the URL of puzzle.json in Application Support.
    private static func savedPuzzleURL() -> URL? {
        do {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return directory.appending(path: "puzzle.json")
        } catch {
            print(error)
            return nil
        }
    }
}
