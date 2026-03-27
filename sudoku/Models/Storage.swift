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
    
    /// Lazily loaded puzzle collection from the bundled puzzles.json file.
    /// Decoded once on first access and cached for the lifetime of the app.
    private static let cachedCollection: Result<[Puzzle], Error> = {
        do {
            guard let url = Bundle.main.url(forResource: "puzzles", withExtension: "json") else {
                throw StorageError.missingResource("puzzles.json")
            }
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([RawPuzzle].self, from: data)
            let puzzles = raw.map { entry in
                var puzzle = Puzzle()
                puzzle.number = entry.number
                puzzle.difficulty = entry.difficulty
                puzzle.cells = entry.puzzle.map { value in
                    guard let value else { return .empty }
                    return .clue(value)
                }
                return puzzle
            }
            return .success(puzzles)
        } catch {
            return .failure(error)
        }
    }()
    
    /// Returns the cached puzzle collection, decoded once from the bundled JSON.
    static func loadPuzzleCollection() throws -> [Puzzle] {
        try cachedCollection.get()
    }
    
    /// The total number of puzzles available in the collection.
    static var puzzleCount: Int {
        (try? cachedCollection.get().count) ?? 0
    }
    
    /// Loads the saved game from Application Support.
    static func load() throws -> Puzzle {
        let url = try savedPuzzleURL()
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Puzzle.self, from: data)
    }
    
    /// Saves the current game to Application Support.
    static func save(_ puzzle: Puzzle) throws {
        let url = try savedPuzzleURL()
        let data = try JSONEncoder().encode(puzzle)
        try data.write(to: url)
    }
    
    /// Returns the URL of puzzle.json in Application Support.
    private static func savedPuzzleURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return directory.appending(path: "puzzle.json")
    }
}

enum StorageError: LocalizedError {
    case missingResource(String)
    
    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing bundled resource: \(name)"
        }
    }
}
