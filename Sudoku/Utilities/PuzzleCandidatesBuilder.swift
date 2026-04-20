import Foundation

enum PuzzleCandidatesBuilder {
    static func possibilities(for puzzle: Puzzle) -> Puzzle {
        var cells = puzzle.cells
        
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard cells[row][col].value == nil else { continue }
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                cells[row][col] = candidates.isEmpty ? .empty : .notes(candidates)
            }
        }
        
        return Puzzle(cells: cells)
    }
    
    static func prunedNotes(in puzzle: Puzzle) -> Puzzle {
        var cells = puzzle.cells
        
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard case .notes(let existing) = cells[row][col] else { continue }
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                let remaining = existing.intersection(candidates)
                cells[row][col] = remaining.isEmpty ? .empty : .notes(remaining)
            }
        }
        
        return Puzzle(cells: cells)
    }
    
    static func hintPreview(from puzzle: Puzzle, applying hints: [HintResult]) -> Puzzle {
        let removedCandidates = Set(
            hints.flatMap(\.eliminations).map { CandidateKey(row: $0.row, col: $0.col, digit: $0.digit) }
        )
        
        var cells = puzzle.cells
        
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard cells[row][col].value == nil else { continue }
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                let remaining = candidates.filter { digit in
                    !removedCandidates.contains(CandidateKey(row: row, col: col, digit: digit))
                }
                cells[row][col] = remaining.isEmpty ? .empty : .notes(remaining)
            }
        }
        
        return Puzzle(cells: cells)
    }
}

private struct CandidateKey: Hashable {
    let row: Int
    let col: Int
    let digit: Int
}
