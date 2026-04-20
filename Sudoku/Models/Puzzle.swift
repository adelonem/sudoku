import Foundation

struct Puzzle: Codable {
    static let size = 9
    static let blockSize = 3
    
    let cells: [[Cell]]
    
    init(values: [[Int]]) {
        cells = values.map { row in
            row.map { $0 > 0 ? .fixed($0) : .empty }
        }
    }
    
    init(cells: [[Cell]]) {
        self.cells = cells
    }
}

extension Puzzle {
    // MARK: - Derived State
    
    var emptyCellCount: Int {
        cells.reduce(into: 0) { count, row in
            count += row.reduce(into: 0) { rowCount, cell in
                rowCount += cell.value == nil ? 1 : 0
            }
        }
    }
    
    var isFilled: Bool {
        cells.allSatisfy { row in
            row.allSatisfy { $0.value != nil }
        }
    }
    
    func clearingEditableCells() -> Puzzle {
        Puzzle(cells: cells.map { row in
            row.map { cell in
                cell.isFixed ? cell : .empty
            }
        })
    }
}

extension Puzzle {
    // MARK: - Mutating Copies
    
    func clearingCell(row: Int, col: Int) -> Puzzle {
        guard !cells[row][col].isFixed else { return self }
        var newCells = cells
        newCells[row][col] = .empty
        return Puzzle(cells: newCells)
    }
    
    func settingValue(_ value: Int, row: Int, col: Int) -> Puzzle {
        guard !cells[row][col].isFixed else { return self }
        var newCells = cells
        newCells[row][col] = .guess(value)
        return Puzzle(cells: newCells)
    }
    
    func togglingNote(_ note: Int, row: Int, col: Int) -> Puzzle {
        guard !cells[row][col].isFixed, !cells[row][col].isGuess else { return self }
        
        var candidates: Set<Int>
        if case .notes(let existing) = cells[row][col] {
            candidates = existing
        } else {
            candidates = []
        }
        
        if candidates.contains(note) {
            candidates.remove(note)
        } else {
            candidates.insert(note)
        }
        
        var newCells = cells
        newCells[row][col] = candidates.isEmpty ? .empty : .notes(candidates)
        return Puzzle(cells: newCells)
    }
}

extension Puzzle {
    static let sample = Puzzle(values: [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ])
}
