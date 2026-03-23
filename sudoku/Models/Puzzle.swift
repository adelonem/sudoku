//
//  Puzzle.swift
//  sudoku
//

struct Puzzle: Codable {
    var number: Int?
    var difficulty: String?
    var cells: [Cell]
    
    init() {
        cells = Array(repeating: .empty, count: Self.size * Self.size)
    }
    
    static let size = 9
    static let blockSize = 3
    
    subscript(row: Int, col: Int) -> Cell {
        get {
            precondition(0..<Self.size ~= row && 0..<Self.size ~= col, "Cell index out of bounds: (\(row), \(col))")
            return cells[row * Self.size + col]
        }
        set {
            precondition(0..<Self.size ~= row && 0..<Self.size ~= col, "Cell index out of bounds: (\(row), \(col))")
            cells[row * Self.size + col] = newValue
        }
    }
    
    subscript(position: CellPosition) -> Cell {
        get { self[position.row, position.col] }
        set { self[position.row, position.col] = newValue }
    }
    
    /// Returns the indices of all cells sharing a row, column, or 3×3 block with (`row`, `col`), excluding the cell itself.
    static func peerIndices(ofRow row: Int, col: Int) -> Set<Int> {
        var result: Set<Int> = []
        let selfIndex = row * size + col
        
        // Same row
        for c in 0..<size { result.insert(row * size + c) }
        
        // Same column
        for r in 0..<size { result.insert(r * size + col) }
        
        // Same block
        let blockRow = (row / blockSize) * blockSize
        let blockCol = (col / blockSize) * blockSize
        for r in blockRow..<blockRow + blockSize {
            for c in blockCol..<blockCol + blockSize {
                result.insert(r * size + c)
            }
        }
        
        result.remove(selfIndex)
        return result
    }
}
