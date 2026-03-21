//
//  PuzzleStorage.swift
//  sudoku
//

import Foundation

class Storage {
    static func load() -> [Int?]? {
        guard let url = url() else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Int?].self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
    
    static func save (_ values: [Int?]) {
        guard let url = url() else {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(values)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
    
    static func url() -> URL? {
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return directory.appendingPathComponent("puzzle.json")
        } catch {
            print(error)
            return nil
        }
    }
}
