//
//  HintDetector.swift
//  Sudoku
//
//  Stateless detector that identifies the easiest applicable sudoku technique
//  in the current puzzle state and returns a HintResult describing it.
//

import Foundation

enum HintDetector {
    
    // MARK: - Private candidate key for chain tracking
    
    private struct CandKey: Hashable {
        let row: Int, col: Int, digit: Int
    }
    
    private struct ForcingBranchResult {
        let placements: [(Pos, Int)]
        let contradiction: Bool
    }
    
    // MARK: - Public entry points
    
    /// Returns an ordered sequence of hints leading from the first applicable technique
    /// to a placement (nakedSingles / hiddenSingles). Intermediate steps are elimination
    /// techniques whose cumulative effect makes the placement reachable.
    static func findHintChain(in puzzle: Puzzle) -> [HintResult] {
        var chain: [HintResult] = []
        var eliminatedSet: Set<CandKey> = []
        
        for _ in 0..<12 {
            var cands = computeCandidates(in: puzzle)
            for key in eliminatedSet { cands[key.row][key.col].remove(key.digit) }
            guard let hint = findHint(cands: cands, puzzle: puzzle) else { break }
            chain.append(hint)
            guard hint.technique != .nakedSingles && hint.technique != .hiddenSingles else { break }
            let newKeys = Set(hint.eliminations.map { CandKey(row: $0.row, col: $0.col, digit: $0.digit) })
            guard !newKeys.isSubset(of: eliminatedSet) else { break }  // no progress
            eliminatedSet.formUnion(newKeys)
        }
        return chain
    }
    
    static func findHint(in puzzle: Puzzle) -> HintResult? {
        let cands = computeCandidates(in: puzzle)
        return findHint(cands: cands, puzzle: puzzle)
    }
    
    private static func findHint(cands: [[Set<Int>]], puzzle: Puzzle) -> HintResult? {
        if let h = nakedSingle(puzzle: puzzle, cands: cands)    { return h }
        if let h = hiddenSingle(puzzle: puzzle, cands: cands)   { return h }
        if let h = nakedSubset(puzzle: puzzle, cands: cands, size: 2, technique: .nakedPairs)   { return h }
        if let h = nakedSubset(puzzle: puzzle, cands: cands, size: 3, technique: .nakedTriples) { return h }
        if let h = nakedSubset(puzzle: puzzle, cands: cands, size: 4, technique: .nakedQuads)   { return h }
        if let h = pointingPairs(puzzle: puzzle, cands: cands)  { return h }
        if let h = hiddenSubset(puzzle: puzzle, cands: cands, size: 2, technique: .hiddenPairs)   { return h }
        if let h = hiddenSubset(puzzle: puzzle, cands: cands, size: 3, technique: .hiddenTriples) { return h }
        if let h = hiddenSubset(puzzle: puzzle, cands: cands, size: 4, technique: .hiddenQuads)   { return h }
        if let h = fish(cands: cands, size: 2, technique: .xWing)     { return h }
        if let h = skyscraper(cands: cands)                            { return h }
        if let h = simpleColoring(cands: cands)                        { return h }
        if let h = uniqueRectangle(cands: cands)                       { return h }
        if let h = fish(cands: cands, size: 3, technique: .swordfish)  { return h }
        if let h = fish(cands: cands, size: 4, technique: .jellyfish)  { return h }
        if let h = finnedXWing(cands: cands)                           { return h }
        if let h = xyWing(cands: cands)                                { return h }
        if let h = xyzWing(cands: cands)                               { return h }
        if let h = wxyzWing(cands: cands)                              { return h }
        if let h = aic(cands: cands)                                   { return h }
        return forcingChains(puzzle: puzzle, cands: cands)
    }
    
    // MARK: - Utilities
    
    private typealias Pos = (row: Int, col: Int)
    
    private static func computeCandidates(in puzzle: Puzzle) -> [[Set<Int>]] {
        (0..<9).map { row in
            (0..<9).map { col in
                PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
            }
        }
    }
    
    private static func computeCandidates(in puzzle: Puzzle, removing removed: Set<CandKey>) -> [[Set<Int>]] {
        let candidates = computeCandidates(in: puzzle)
        guard !removed.isEmpty else { return candidates }
        
        return (0..<9).map { row in
            (0..<9).map { col in
                candidates[row][col].filter { digit in
                    !removed.contains(CandKey(row: row, col: col, digit: digit))
                }
            }
        }
    }
    
    private static func removedCandidates(in puzzle: Puzzle, from cands: [[Set<Int>]]) -> Set<CandKey> {
        let actual = computeCandidates(in: puzzle)
        var removed: Set<CandKey> = []
        
        for row in 0..<9 {
            for col in 0..<9 {
                for digit in actual[row][col].subtracting(cands[row][col]) {
                    removed.insert(CandKey(row: row, col: col, digit: digit))
                }
            }
        }
        
        return removed
    }
    
    /// All 27 units (9 rows + 9 cols + 9 boxes) as arrays of positions.
    private static let allUnits: [[(row: Int, col: Int)]] = {
        var units: [[(row: Int, col: Int)]] = []
        for r in 0..<9 { units.append((0..<9).map { (r, $0) }) }
        for c in 0..<9 { units.append((0..<9).map { ($0, c) }) }
        for br in 0..<3 {
            for bc in 0..<3 {
                var box: [(row: Int, col: Int)] = []
                for dr in 0..<3 { for dc in 0..<3 { box.append((br*3+dr, bc*3+dc)) } }
                units.append(box)
            }
        }
        return units
    }()
    
    private static func combinations<T>(_ array: [T], _ k: Int) -> [[T]] {
        guard k > 0 && k <= array.count else { return k == 0 ? [[]] : [] }
        var result: [[T]] = []
        func helper(_ start: Int, _ current: [T]) {
            if current.count == k { result.append(current); return }
            guard array.count - start >= k - current.count else { return }
            for i in start..<array.count {
                helper(i + 1, current + [array[i]])
            }
        }
        helper(0, [])
        return result
    }
    
    private static func seesEachOther(_ a: Pos, _ b: Pos) -> Bool {
        guard a.row != b.row || a.col != b.col else { return false }
        if a.row == b.row || a.col == b.col { return true }
        return a.row/3 == b.row/3 && a.col/3 == b.col/3
    }
    
    private static func peers(of p: Pos) -> [Pos] {
        PuzzleSolver.peerPositions(ofRow: p.row, col: p.col).map { (row: $0.0, col: $0.1) }
    }
    
    private static func makeHint(
        _ technique: SudokuTechnique, digit: Int?,
        primary: [Pos], secondary: [Pos],
        explanation: String, reasoning: [String] = [],
        eliminations: [(row: Int, col: Int, digit: Int)]? = nil
    ) -> HintResult {
        let elims: [(row: Int, col: Int, digit: Int)]
        if let e = eliminations {
            elims = e
        } else if let d = digit, technique != .nakedSingles, technique != .hiddenSingles {
            elims = secondary.map { (row: $0.row, col: $0.col, digit: d) }
        } else {
            elims = []
        }
        return HintResult(
            technique: technique, digit: digit,
            primaryCells: primary.map { (row: $0.row, col: $0.col) },
            secondaryCells: secondary.map { (row: $0.row, col: $0.col) },
            title: technique.title,
            explanation: explanation,
            reasoning: reasoning,
            eliminations: elims
        )
    }
    
    private static func unitLabel(_ unit: [Pos]) -> String {
        if unit.allSatisfy({ $0.row == unit[0].row }) { return String(localized: "row \(unit[0].row + 1)") }
        if unit.allSatisfy({ $0.col == unit[0].col }) { return String(localized: "column \(unit[0].col + 1)") }
        return String(localized: "box (\(unit[0].row/3 + 1),\(unit[0].col/3 + 1))")
    }
    
    // MARK: - Reasoning helpers
    
    /// Returns a short label for a position within its unit.
    /// - In a row unit → "col. C" ; in a col unit → "lig. R" ; in a box → "lig. R, col. C"
    private static func posLabel(_ pos: Pos, in unit: [Pos]) -> String {
        if unit.allSatisfy({ $0.row == unit[0].row }) { return String(localized: "c.\(pos.col + 1)") }
        if unit.allSatisfy({ $0.col == unit[0].col }) { return String(localized: "r.\(pos.row + 1)") }
        return String(localized: "r.\(pos.row + 1), c.\(pos.col + 1)")
    }
    
    private static func cellLabel(_ pos: Pos) -> String {
        "R\(pos.row + 1)C\(pos.col + 1)"
    }
    
    private static func uniquePositions(_ positions: [Pos]) -> [Pos] {
        struct PositionKey: Hashable {
            let row: Int
            let col: Int
        }
        
        var seen: Set<PositionKey> = []
        return positions.filter { pos in
            seen.insert(PositionKey(row: pos.row, col: pos.col)).inserted
        }
    }
    
    private static func cellList(_ positions: [Pos], limit: Int = 8) -> String {
        let sorted = uniquePositions(positions).sorted {
            $0.row == $1.row ? $0.col < $1.col : $0.row < $1.row
        }
        let prefix = Array(sorted.prefix(limit)).map { Self.cellLabel($0) }.joined(separator: ", ")
        if sorted.count > limit {
            return "\(prefix), ..."
        }
        return prefix
    }
    
    private static func digitList(_ digits: [Int]) -> String {
        digits.sorted().map(String.init).joined(separator: ", ")
    }
    
    private static func lineLabel(_ index: Int, byRow: Bool) -> String {
        byRow
        ? String(localized: "row \(index + 1)")
        : String(localized: "column \(index + 1)")
    }
    
    private static func lineList(_ indices: [Int], byRow: Bool) -> String {
        indices.sorted().map { lineLabel($0, byRow: byRow) }.joined(separator: ", ")
    }
    
    private static func coverLabel(_ index: Int, byRow: Bool) -> String {
        byRow
        ? String(localized: "column \(index + 1)")
        : String(localized: "row \(index + 1)")
    }
    
    private static func coverList(_ indices: [Int], byRow: Bool) -> String {
        indices.sorted().map { coverLabel($0, byRow: byRow) }.joined(separator: ", ")
    }
    
    /// Explains why `digit` is not a candidate at `pos`, by finding which peer already holds it.
    private static func whyExcluded(digit: Int, at pos: Pos, in puzzle: Puzzle) -> String {
        for (r, c) in PuzzleSolver.peerPositions(ofRow: pos.row, col: pos.col) {
            guard puzzle.cells[r][c].value == digit else { continue }
            if r == pos.row { return String(localized: "\(digit) is already at row \(r + 1), col. \(c + 1)") }
            if c == pos.col { return String(localized: "\(digit) is already at row \(r + 1), col. \(c + 1)") }
            return String(localized: "\(digit) is already in box (\(r/3 + 1),\(c/3 + 1)), row \(r + 1), col. \(c + 1)")
        }
        return String(localized: "not a candidate")
    }
    
    /// Builds the step-by-step reasoning for a Naked Single at (row, col) with `digit`.
    /// Groups eliminations by row / column / box to stay compact.
    private static func nakedSingleReasoning(puzzle: Puzzle, row: Int, col: Int, digit: Int) -> [String] {
        var rowDigits: [Int] = [], colDigits: [Int] = [], boxDigits: [Int] = []
        for (r, c) in PuzzleSolver.peerPositions(ofRow: row, col: col) {
            guard let v = puzzle.cells[r][c].value else { continue }
            if r == row      { rowDigits.append(v) }
            else if c == col { colDigits.append(v) }
            else             { boxDigits.append(v) }
        }
        var steps: [String] = []
        if !rowDigits.isEmpty {
            let list = rowDigits.sorted().map(String.init).joined(separator: ", ")
            steps.append(String(localized: "Row \(row + 1): already contains \(list)"))
        }
        if !colDigits.isEmpty {
            let list = colDigits.sorted().map(String.init).joined(separator: ", ")
            steps.append(String(localized: "Column \(col + 1): already contains \(list)"))
        }
        if !boxDigits.isEmpty {
            let list = boxDigits.sorted().map(String.init).joined(separator: ", ")
            steps.append(String(localized: "Box (\(row/3 + 1),\(col/3 + 1)): already contains \(list)"))
        }
        steps.append(String(localized: "→ Only \(digit) remains possible"))
        return steps
    }
    
    /// Builds the step-by-step reasoning for a Hidden Single: `digit` in `unit`, only at `target`.
    /// Occupied cells are grouped; each excluded empty cell gets its own reason.
    private static func hiddenSingleReasoning(puzzle: Puzzle, cands: [[Set<Int>]], unit: [Pos], digit: Int, target: Pos) -> [String] {
        var steps: [String] = []
        let occupied = unit.filter { p in
            !(p.row == target.row && p.col == target.col) && puzzle.cells[p.row][p.col].value != nil
        }
        if !occupied.isEmpty {
            let labels = occupied.map { posLabel($0, in: unit) }.joined(separator: ", ")
            steps.append(String(localized: "Occupied (no candidates): \(labels)"))
        }
        for pos in unit where !(pos.row == target.row && pos.col == target.col) && puzzle.cells[pos.row][pos.col].value == nil {
            let label = posLabel(pos, in: unit)
            let reason = whyExcluded(digit: digit, at: pos, in: puzzle)
            steps.append(String(localized: "\(label): \(reason)"))
        }
        let targetLabel = posLabel(target, in: unit)
        steps.append(String(localized: "→ Only \(targetLabel) can hold \(digit)"))
        return steps
    }
    
    // MARK: - Palier 1: Naked Single, Hidden Single
    
    private static func nakedSingle(puzzle: Puzzle, cands: [[Set<Int>]]) -> HintResult? {
        for row in 0..<9 {
            for col in 0..<9 {
                guard cands[row][col].count == 1, let digit = cands[row][col].first else { continue }
                let primary: [Pos] = [(row, col)]
                let secondary = peers(of: (row, col)).filter { puzzle.cells[$0.row][$0.col].value != nil }
                let reasoning = nakedSingleReasoning(puzzle: puzzle, row: row, col: col, digit: digit)
                return makeHint(.nakedSingles, digit: digit, primary: primary, secondary: secondary,
                                explanation: String(localized: "Cell at row \(row+1), column \(col+1) has only one possible candidate: \(digit)."),
                                reasoning: reasoning)
            }
        }
        return nil
    }
    
    private static func hiddenSingle(puzzle: Puzzle, cands: [[Set<Int>]]) -> HintResult? {
        for unit in allUnits {
            for digit in 1...9 {
                let places = unit.filter { cands[$0.row][$0.col].contains(digit) }
                guard places.count == 1, let pos = places.first else { continue }
                let secondary = unit.filter { ($0.row != pos.row || $0.col != pos.col) && puzzle.cells[$0.row][$0.col].value != nil }
                let reasoning = hiddenSingleReasoning(puzzle: puzzle, cands: cands, unit: unit, digit: digit, target: pos)
                let unitName = unitLabel(unit)
                return makeHint(.hiddenSingles, digit: digit, primary: [pos], secondary: secondary,
                                explanation: String(localized: "In \(unitName), digit \(digit) can only be placed at row \(pos.row+1), column \(pos.col+1)."),
                                reasoning: reasoning)
            }
        }
        return nil
    }
    
    // MARK: - Palier 2: Naked Subsets, Pointing Pairs
    
    private static func nakedSubset(puzzle: Puzzle, cands: [[Set<Int>]], size: Int, technique: SudokuTechnique) -> HintResult? {
        for unit in allUnits {
            let empty = unit.filter { !cands[$0.row][$0.col].isEmpty }
            guard empty.count > size else { continue }
            for combo in combinations(empty, size) {
                let union = combo.reduce(Set<Int>()) { $0.union(cands[$1.row][$1.col]) }
                guard union.count == size else { continue }
                let secondary = empty.filter { p in
                    !combo.contains(where: { $0.row == p.row && $0.col == p.col })
                    && !cands[p.row][p.col].isDisjoint(with: union)
                }
                guard !secondary.isEmpty else { continue }
                let eliminations: [(row: Int, col: Int, digit: Int)] = secondary.flatMap { cell in
                    cands[cell.row][cell.col].intersection(union).map { d in
                        (row: cell.row, col: cell.col, digit: d)
                    }
                }
                let digits = union.sorted().map(String.init).joined(separator: ",")
                let comboLabels = combo.map { "R\($0.row+1)C\($0.col+1)" }.joined(separator: " / ")
                let elimLabels  = secondary.map { "R\($0.row+1)C\($0.col+1)" }.joined(separator: " / ")
                let unitName = unitLabel(unit)
                let techTitle = technique.title
                let reasoning: [String] = [
                    String(localized: "The \(size) cells (\(comboLabels)) share exactly candidates \(digits)."),
                    String(localized: "These \(size) digits can only go in these \(size) cells of \(unitName)."),
                    String(localized: "→ Eliminate \(digits) from cells: \(elimLabels)")
                ]
                return makeHint(technique, digit: nil, primary: combo, secondary: secondary,
                                explanation: String(localized: "\(techTitle) on \(digits) in \(unitName): these digits can be eliminated from other cells."),
                                reasoning: reasoning, eliminations: eliminations)
            }
        }
        return nil
    }
    
    private static func pointingPairs(puzzle: Puzzle, cands: [[Set<Int>]]) -> HintResult? {
        for br in 0..<3 {
            for bc in 0..<3 {
                let boxCells: [Pos] = (0..<3).flatMap { dr in (0..<3).map { dc -> Pos in (br*3+dr, bc*3+dc) } }
                for digit in 1...9 {
                    let inBox = boxCells.filter { cands[$0.row][$0.col].contains(digit) }
                    guard inBox.count >= 2 else { continue }
                    if inBox.allSatisfy({ $0.row == inBox[0].row }) {
                        let r = inBox[0].row
                        let secondary = (0..<9).compactMap { c -> Pos? in
                            c/3 != bc && cands[r][c].contains(digit) ? (r, c) : nil
                        }
                        if !secondary.isEmpty {
                            let primCols = inBox.map { String(localized: "c.\($0.col+1)") }.joined(separator: ", ")
                            let elimCols = secondary.map { String(localized: "c.\($0.col+1)") }.joined(separator: ", ")
                            let reasoning: [String] = [
                                String(localized: "In box (\(br+1),\(bc+1)), \(digit) is only a candidate at \(primCols) of row \(r+1)."),
                                String(localized: "If \(digit) were elsewhere in row \(r+1), box (\(br+1),\(bc+1)) would have no room for it."),
                                String(localized: "→ Eliminate \(digit) from row \(r+1) at \(elimCols)")
                            ]
                            return makeHint(.pointingPairs, digit: digit, primary: inBox, secondary: secondary,
                                            explanation: String(localized: "In box (\(br+1),\(bc+1)), \(digit) is confined to row \(r+1): it can be eliminated from the rest of this row."),
                                            reasoning: reasoning)
                        }
                    }
                    if inBox.allSatisfy({ $0.col == inBox[0].col }) {
                        let c = inBox[0].col
                        let secondary = (0..<9).compactMap { r -> Pos? in
                            r/3 != br && cands[r][c].contains(digit) ? (r, c) : nil
                        }
                        if !secondary.isEmpty {
                            let primRows = inBox.map { String(localized: "r.\($0.row+1)") }.joined(separator: ", ")
                            let elimRows = secondary.map { String(localized: "r.\($0.row+1)") }.joined(separator: ", ")
                            let reasoning: [String] = [
                                String(localized: "In box (\(br+1),\(bc+1)), \(digit) is only a candidate at \(primRows) of column \(c+1)."),
                                String(localized: "If \(digit) were elsewhere in column \(c+1), box (\(br+1),\(bc+1)) would have no room for it."),
                                String(localized: "→ Eliminate \(digit) from column \(c+1) at \(elimRows)")
                            ]
                            return makeHint(.pointingPairs, digit: digit, primary: inBox, secondary: secondary,
                                            explanation: String(localized: "In box (\(br+1),\(bc+1)), \(digit) is confined to column \(c+1): it can be eliminated from the rest of this column."),
                                            reasoning: reasoning)
                        }
                    }
                }
            }
        }
        for digit in 1...9 {
            for r in 0..<9 {
                let cols = (0..<9).filter { cands[r][$0].contains(digit) }
                guard cols.count >= 2 && Set(cols.map { $0/3 }).count == 1 else { continue }
                let bc = cols[0]/3, br = r/3
                let primary: [Pos] = cols.map { (r, $0) }
                let secondary: [Pos] = (0..<3).flatMap { dr in (0..<3).compactMap { dc -> Pos? in
                    let rr = br*3+dr, cc = bc*3+dc
                    return rr != r && cands[rr][cc].contains(digit) ? (rr, cc) : nil
                }}
                if !secondary.isEmpty {
                    let primCols = cols.map { String(localized: "c.\($0+1)") }.joined(separator: ", ")
                    let elimLabels = secondary.map { "R\($0.row+1)C\($0.col+1)" }.joined(separator: " / ")
                    let reasoning: [String] = [
                        String(localized: "In row \(r+1), \(digit) is only a candidate at \(primCols), all in box (\(br+1),\(bc+1))."),
                        String(localized: "\(digit) must be in this box on row \(r+1): it cannot be elsewhere in the box."),
                        String(localized: "→ Eliminate \(digit) from box (\(br+1),\(bc+1)) at: \(elimLabels)")
                    ]
                    return makeHint(.pointingPairs, digit: digit, primary: primary, secondary: secondary,
                                    explanation: String(localized: "In row \(r+1), \(digit) is confined to box (\(br+1),\(bc+1)): it can be eliminated from the rest of this box."),
                                    reasoning: reasoning)
                }
            }
            for c in 0..<9 {
                let rows = (0..<9).filter { cands[$0][c].contains(digit) }
                guard rows.count >= 2 && Set(rows.map { $0/3 }).count == 1 else { continue }
                let br = rows[0]/3, bc = c/3
                let primary: [Pos] = rows.map { ($0, c) }
                let secondary: [Pos] = (0..<3).flatMap { dr in (0..<3).compactMap { dc -> Pos? in
                    let rr = br*3+dr, cc = bc*3+dc
                    return cc != c && cands[rr][cc].contains(digit) ? (rr, cc) : nil
                }}
                if !secondary.isEmpty {
                    let primRows = rows.map { String(localized: "r.\($0+1)") }.joined(separator: ", ")
                    let elimLabels = secondary.map { "R\($0.row+1)C\($0.col+1)" }.joined(separator: " / ")
                    let reasoning: [String] = [
                        String(localized: "In column \(c+1), \(digit) is only a candidate at \(primRows), all in box (\(br+1),\(bc+1))."),
                        String(localized: "\(digit) must be in this box on column \(c+1): it cannot be elsewhere in the box."),
                        String(localized: "→ Eliminate \(digit) from box (\(br+1),\(bc+1)) at: \(elimLabels)")
                    ]
                    return makeHint(.pointingPairs, digit: digit, primary: primary, secondary: secondary,
                                    explanation: String(localized: "In column \(c+1), \(digit) is confined to box (\(br+1),\(bc+1)): it can be eliminated from the rest of this box."),
                                    reasoning: reasoning)
                }
            }
        }
        return nil
    }
    
    // MARK: - Palier 3: Hidden Subsets
    
    private static func hiddenSubset(puzzle: Puzzle, cands: [[Set<Int>]], size: Int, technique: SudokuTechnique) -> HintResult? {
        for unit in allUnits {
            let empty = unit.filter { !cands[$0.row][$0.col].isEmpty }
            guard empty.count > size else { continue }
            for digitCombo in combinations(Array(1...9), size) {
                let digitSet = Set(digitCombo)
                let cells = empty.filter { !cands[$0.row][$0.col].isDisjoint(with: digitSet) }
                guard cells.count == size else { continue }
                guard digitCombo.allSatisfy({ d in cells.contains { cands[$0.row][$0.col].contains(d) } }) else { continue }
                guard cells.contains(where: { !cands[$0.row][$0.col].isSubset(of: digitSet) }) else { continue }
                let hiddenDigitSet = Set(digitCombo)
                let eliminations: [(row: Int, col: Int, digit: Int)] = cells.flatMap { cell in
                    cands[cell.row][cell.col].subtracting(hiddenDigitSet).map { d in
                        (row: cell.row, col: cell.col, digit: d)
                    }
                }
                let secondary = empty.filter { p in !cells.contains { $0.row == p.row && $0.col == p.col } }
                let digits = digitCombo.map(String.init).joined(separator: ",")
                let cellLabels = cells.map { "R\($0.row+1)C\($0.col+1)" }.joined(separator: " / ")
                let unitName = unitLabel(unit)
                let techTitle = technique.title
                let reasoning: [String] = [
                    String(localized: "Digits \(digits) only appear as candidates in these \(size) cells of \(unitName): \(cellLabels)."),
                    String(localized: "These digits must be placed there — other candidates in these cells can be eliminated."),
                    String(localized: "→ Candidates to eliminate: any digit outside {\(digits)} in these cells")
                ]
                return makeHint(technique, digit: nil, primary: cells, secondary: secondary,
                                explanation: String(localized: "\(techTitle) \(digits) in \(unitName): other candidates in these cells can be eliminated."),
                                reasoning: reasoning, eliminations: eliminations)
            }
        }
        return nil
    }
    
    // MARK: - Palier 4: Fish, Finned X-Wing
    
    private static func fish(cands: [[Set<Int>]], size: Int, technique: SudokuTechnique) -> HintResult? {
        for digit in 1...9 {
            if let r = fishForDigit(cands: cands, digit: digit, size: size, technique: technique, byRow: true)  { return r }
            if let r = fishForDigit(cands: cands, digit: digit, size: size, technique: technique, byRow: false) { return r }
        }
        return nil
    }
    
    private static func fishForDigit(cands: [[Set<Int>]], digit: Int, size: Int, technique: SudokuTechnique, byRow: Bool) -> HintResult? {
        var eligible: [(idx: Int, positions: [Int])] = []
        for i in 0..<9 {
            let pos = byRow ? (0..<9).filter { cands[i][$0].contains(digit) }
            : (0..<9).filter { cands[$0][i].contains(digit) }
            if pos.count >= 2 && pos.count <= size { eligible.append((i, pos)) }
        }
        guard eligible.count >= size else { return nil }
        for combo in combinations(eligible, size) {
            let cover = Set(combo.flatMap { $0.positions })
            guard cover.count == size else { continue }
            let primary: [Pos] = combo.flatMap { line in line.positions.map { p -> Pos in byRow ? (line.idx, p) : (p, line.idx) } }
            let lineSet = Set(combo.map { $0.idx })
            var secondary: [Pos] = []
            for i in 0..<9 where !lineSet.contains(i) {
                for p in cover {
                    let pos: Pos = byRow ? (i, p) : (p, i)
                    if cands[pos.row][pos.col].contains(digit) { secondary.append(pos) }
                }
            }
            guard !secondary.isEmpty else { continue }
            let techTitle = technique.title
            let baseLines = combo.map(\.idx)
            let coverLines = Array(cover)
            let reasoning: [String] = [
                String(localized: "\(digit) only appears in \(lineList(baseLines, byRow: byRow)) at \(coverList(coverLines, byRow: byRow))."),
                String(localized: "These highlighted cells form a \(techTitle) pattern, so \(digit) must stay inside those \(coverLines.count) \(byRow ? "shared columns" : "shared rows")."),
                String(localized: "→ Eliminate \(digit) from \(cellList(secondary)).")
            ]
            return makeHint(technique, digit: digit, primary: primary, secondary: secondary,
                            explanation: String(localized: "\(techTitle) on digit \(digit): the highlighted pattern locks \(digit) into \(coverList(coverLines, byRow: byRow)), so it can be removed from the other intersecting cells."),
                            reasoning: reasoning)
        }
        return nil
    }
    
    private static func finnedXWing(cands: [[Set<Int>]]) -> HintResult? {
        for digit in 1...9 {
            if let r = finnedForDigit(cands: cands, digit: digit, byRow: true)  { return r }
            if let r = finnedForDigit(cands: cands, digit: digit, byRow: false) { return r }
        }
        return nil
    }
    
    private static func finnedForDigit(cands: [[Set<Int>]], digit: Int, byRow: Bool) -> HintResult? {
        for baseIdx in 0..<9 {
            let basePos = byRow ? (0..<9).filter { cands[baseIdx][$0].contains(digit) }
            : (0..<9).filter { cands[$0][baseIdx].contains(digit) }
            guard basePos.count == 2 else { continue }
            let (bp0, bp1) = (basePos[0], basePos[1])
            let boxBase = baseIdx / 3
            for finnedIdx in (boxBase*3..<boxBase*3+3) where finnedIdx != baseIdx {
                let finnedPos = byRow ? (0..<9).filter { cands[finnedIdx][$0].contains(digit) }
                : (0..<9).filter { cands[$0][finnedIdx].contains(digit) }
                guard finnedPos.contains(bp0) && finnedPos.contains(bp1) else { continue }
                let fins = finnedPos.filter { $0 != bp0 && $0 != bp1 }
                guard !fins.isEmpty && fins.count <= 2 else { continue }
                guard Set(fins.map { $0/3 }).count == 1 else { continue }
                let finBoxCol = fins[0] / 3
                guard bp0/3 == finBoxCol || bp1/3 == finBoxCol else { continue }
                let baseColInFinBox = bp0/3 == finBoxCol ? bp0 : bp1
                var secondary: [Pos] = []
                for dr in 0..<3 {
                    let r = boxBase*3 + dr
                    guard r != baseIdx && r != finnedIdx else { continue }
                    let p: Pos = byRow ? (r, baseColInFinBox) : (baseColInFinBox, r)
                    if cands[p.row][p.col].contains(digit) { secondary.append(p) }
                }
                guard !secondary.isEmpty else { continue }
                let primary: [Pos] = basePos.map { byRow ? (baseIdx, $0) : ($0, baseIdx) }
                + finnedPos.map { byRow ? (finnedIdx, $0) : ($0, finnedIdx) }
                let finPositions: [Pos] = fins.map { byRow ? (finnedIdx, $0) : ($0, finnedIdx) }
                let finBox = finPositions[0]
                let reasoning: [String] = [
                    String(localized: "\(digit) forms an almost X-Wing between \(lineLabel(baseIdx, byRow: byRow)) and \(lineLabel(finnedIdx, byRow: byRow))."),
                    String(localized: "The extra fin at \(cellList(finPositions)) keeps the eliminations inside box (\(finBox.row / 3 + 1),\(finBox.col / 3 + 1))."),
                    String(localized: "Cells aligned with the base pattern in that box cannot keep \(digit): \(cellList(secondary))."),
                    String(localized: "→ Eliminate \(digit) from those cells.")
                ]
                return makeHint(.finnedXWing, digit: digit, primary: primary, secondary: secondary,
                                explanation: String(localized: "Finned X-Wing on \(digit): the fin restricts the usual X-Wing eliminations to the shared box."),
                                reasoning: reasoning)
            }
        }
        return nil
    }
    
    // MARK: - Palier 5: Skyscraper, Simple Coloring, Unique Rectangle
    
    private static func skyscraper(cands: [[Set<Int>]]) -> HintResult? {
        for digit in 1...9 {
            if let r = skyscraperForDigit(cands: cands, digit: digit, byRow: true)  { return r }
            if let r = skyscraperForDigit(cands: cands, digit: digit, byRow: false) { return r }
        }
        return nil
    }
    
    private static func skyscraperForDigit(cands: [[Set<Int>]], digit: Int, byRow: Bool) -> HintResult? {
        var lines: [(idx: Int, positions: [Int])] = []
        for i in 0..<9 {
            let pos = byRow ? (0..<9).filter { cands[i][$0].contains(digit) }
            : (0..<9).filter { cands[$0][i].contains(digit) }
            if pos.count == 2 { lines.append((i, pos)) }
        }
        for combo in combinations(lines, 2) {
            let (l1, l2) = (combo[0], combo[1])
            let shared = Set(l1.positions).intersection(Set(l2.positions))
            guard shared.count == 1, let sharedPos = shared.first else { continue }
            let ns1 = l1.positions.first { $0 != sharedPos }!
            let ns2 = l2.positions.first { $0 != sharedPos }!
            let nsp1: Pos = byRow ? (l1.idx, ns1) : (ns1, l1.idx)
            let nsp2: Pos = byRow ? (l2.idx, ns2) : (ns2, l2.idx)
            let primary: [Pos] = l1.positions.map { byRow ? (l1.idx, $0) : ($0, l1.idx) }
            + l2.positions.map { byRow ? (l2.idx, $0) : ($0, l2.idx) }
            var secondary: [Pos] = []
            for r in 0..<9 { for c in 0..<9 {
                let p: Pos = (r, c)
                guard cands[r][c].contains(digit) && seesEachOther(p, nsp1) && seesEachOther(p, nsp2) else { continue }
                guard !primary.contains(where: { $0.row == r && $0.col == c }) else { continue }
                secondary.append(p)
            }}
            guard !secondary.isEmpty else { continue }
            let reasoning: [String] = [
                String(localized: "\(digit) appears twice in \(lineLabel(l1.idx, byRow: byRow)) and \(lineLabel(l2.idx, byRow: byRow)), sharing \(coverLabel(sharedPos, byRow: byRow))."),
                String(localized: "That leaves the two roof cells \(cellLabel(nsp1)) and \(cellLabel(nsp2)) as the only non-shared options for \(digit)."),
                String(localized: "Any cell that sees both roofs cannot contain \(digit): \(cellList(secondary))."),
                String(localized: "→ Eliminate \(digit) from those cells.")
            ]
            return makeHint(.skyscraper, digit: digit, primary: primary, secondary: secondary,
                            explanation: String(localized: "Skyscraper on \(digit): the two roof cells force \(digit) into one of them, so any cell seeing both roofs loses \(digit)."),
                            reasoning: reasoning)
        }
        return nil
    }
    
    private static func simpleColoring(cands: [[Set<Int>]]) -> HintResult? {
        for digit in 1...9 {
            if let r = simpleColoringForDigit(cands: cands, digit: digit) { return r }
        }
        return nil
    }
    
    private static func simpleColoringForDigit(cands: [[Set<Int>]], digit: Int) -> HintResult? {
        var adj: [Int: Set<Int>] = [:]
        for unit in allUnits {
            let places = unit.filter { cands[$0.row][$0.col].contains(digit) }
            guard places.count == 2 else { continue }
            let i0 = places[0].row * 9 + places[0].col
            let i1 = places[1].row * 9 + places[1].col
            adj[i0, default: []].insert(i1)
            adj[i1, default: []].insert(i0)
        }
        var colored: [Int: Int] = [:]
        for start in adj.keys where colored[start] == nil {
            var queue = [start]; colored[start] = 0; var qi = 0
            while qi < queue.count {
                let node = queue[qi]; qi += 1
                for nb in adj[node, default: []] where colored[nb] == nil {
                    colored[nb] = 1 - colored[node]!
                    queue.append(nb)
                }
            }
            let component = queue
            let grp0 = component.filter { colored[$0] == 0 }
            let grp1 = component.filter { colored[$0] == 1 }
            for grp in [grp0, grp1] {
                let pos = grp.map { Pos(row: $0/9, col: $0%9) }
                for combo in combinations(pos, 2) {
                    guard seesEachOther(combo[0], combo[1]) else { continue }
                    let other = (grp == grp0 ? grp1 : grp0).map { Pos(row: $0/9, col: $0%9) }
                    let reasoning: [String] = [
                        String(localized: "Color the conjugate chain for \(digit) with two alternating colors."),
                        String(localized: "The same color appears in two cells that see each other: \(cellList(pos))."),
                        String(localized: "That color is impossible, so the opposite color survives in \(cellList(other))."),
                        String(localized: "→ Eliminate \(digit) from the conflicting color.")
                    ]
                    return makeHint(.simpleColoring, digit: digit, primary: other, secondary: pos,
                                    explanation: String(localized: "Simple Coloring on \(digit): one color contradicts itself, so every candidate of that color can be removed."),
                                    reasoning: reasoning)
                }
            }
            let pos0 = grp0.map { Pos(row: $0/9, col: $0%9) }
            let pos1 = grp1.map { Pos(row: $0/9, col: $0%9) }
            var secondary: [Pos] = []
            for r in 0..<9 { for c in 0..<9 {
                guard cands[r][c].contains(digit) && colored[r*9+c] == nil else { continue }
                let p = Pos(row: r, col: c)
                if pos0.contains(where: { seesEachOther(p, $0) }) && pos1.contains(where: { seesEachOther(p, $0) }) {
                    secondary.append(p)
                }
            }}
            if !secondary.isEmpty {
                let reasoning: [String] = [
                    String(localized: "Color the chain for \(digit) across the highlighted candidates."),
                    String(localized: "One of the two colors must contain the true \(digit)."),
                    String(localized: "Cells \(cellList(secondary)) see both colors, so they cannot contain \(digit)."),
                    String(localized: "→ Eliminate \(digit) from those cells.")
                ]
                return makeHint(.simpleColoring, digit: digit, primary: pos0 + pos1, secondary: secondary,
                                explanation: String(localized: "Simple Coloring on \(digit): any cell that sees both colors cannot contain \(digit)."),
                                reasoning: reasoning)
            }
        }
        return nil
    }
    
    private static func uniqueRectangle(cands: [[Set<Int>]]) -> HintResult? {
        let bivalue: [Pos] = (0..<9).flatMap { r in (0..<9).compactMap { c -> Pos? in cands[r][c].count == 2 ? (r, c) : nil } }
        for combo in combinations(bivalue, 2) {
            let (c1, c2) = (combo[0], combo[1])
            guard c1.row != c2.row && c1.col != c2.col else { continue }
            guard cands[c1.row][c1.col] == cands[c2.row][c2.col] else { continue }
            let pair = cands[c1.row][c1.col]
            let corners: [Pos] = [c1, c2, (c1.row, c2.col), (c2.row, c1.col)]
            guard Set(corners.map { $0.row/3*3 + $0.col/3 }).count >= 2 else { continue }
            guard corners.allSatisfy({ cands[$0.row][$0.col].isSuperset(of: pair) }) else { continue }
            let nonBivalue = corners.filter { cands[$0.row][$0.col] != pair }
            guard nonBivalue.count == 1, let target = nonBivalue.first else { continue }
            let bivalueCorners = corners.filter { cands[$0.row][$0.col] == pair }
            let pairDigits = pair.sorted()
            let digits = digitList(pairDigits)
            let extraDigits = cands[target.row][target.col].subtracting(pair).sorted()
            let reasoning: [String] = [
                String(localized: "Three corners of the rectangle already contain only \(digits): \(cellList(bivalueCorners))."),
                String(localized: "If \(cellLabel(target)) also kept only \(digits), the rectangle could be completed in two different ways."),
                String(localized: "So \(cellLabel(target)) must use one of its extra candidates: \(digitList(extraDigits))."),
                String(localized: "→ Eliminate \(digits) from \(cellLabel(target)).")
            ]
            let eliminations = pairDigits.map { digit in
                (row: target.row, col: target.col, digit: digit)
            }
            return makeHint(.uniqueRectangle, digit: nil, primary: [target], secondary: bivalueCorners,
                            explanation: String(localized: "Unique Rectangle on \(digits): removing those digits from \(cellLabel(target)) avoids a non-unique solution."),
                            reasoning: reasoning,
                            eliminations: eliminations)
        }
        return nil
    }
    
    // MARK: - Palier 6: XY-Wing, XYZ-Wing, WXYZ-Wing
    
    private static func xyWing(cands: [[Set<Int>]]) -> HintResult? {
        let bivalue: [Pos] = (0..<9).flatMap { r in (0..<9).compactMap { c -> Pos? in cands[r][c].count == 2 ? (r, c) : nil } }
        for pivot in bivalue {
            let pc = cands[pivot.row][pivot.col]; let pa = pc.sorted()
            let (a, b) = (pa[0], pa[1])
            let wings = bivalue.filter { seesEachOther(pivot, $0) }
            for w1 in wings {
                let w1c = cands[w1.row][w1.col]
                guard w1c.contains(a) && !w1c.contains(b), let c = w1c.subtracting([a]).first else { continue }
                for w2 in wings where !(w2.row == w1.row && w2.col == w1.col) {
                    guard cands[w2.row][w2.col] == Set([b, c]) else { continue }
                    var secondary: [Pos] = []
                    for r in 0..<9 { for col in 0..<9 {
                        let p: Pos = (r, col)
                        guard cands[r][col].contains(c) else { continue }
                        guard seesEachOther(p, w1) && seesEachOther(p, w2) else { continue }
                        guard !(p.row == w1.row && p.col == w1.col) && !(p.row == w2.row && p.col == w2.col) && !(p.row == pivot.row && p.col == pivot.col) else { continue }
                        secondary.append(p)
                    }}
                    guard !secondary.isEmpty else { continue }
                    let reasoning: [String] = [
                        String(localized: "Pivot \(cellLabel(pivot)) contains \(a) and \(b)."),
                        String(localized: "Wing \(cellLabel(w1)) links \(a) to \(c), and wing \(cellLabel(w2)) links \(b) to \(c)."),
                        String(localized: "Whatever the pivot becomes, one wing must take \(c), so common peers \(cellList(secondary)) cannot keep \(c)."),
                        String(localized: "→ Eliminate \(c) from those cells.")
                    ]
                    return makeHint(.xyWing, digit: c, primary: [pivot, w1, w2], secondary: secondary,
                                    explanation: String(localized: "XY-Wing: the pivot forces one of its two wings to become \(c), so any cell seeing both wings loses \(c)."),
                                    reasoning: reasoning)
                }
            }
        }
        return nil
    }
    
    private static func xyzWing(cands: [[Set<Int>]]) -> HintResult? {
        let bivalue: [Pos] = (0..<9).flatMap { r in (0..<9).compactMap { c -> Pos? in cands[r][c].count == 2 ? (r, c) : nil } }
        for r in 0..<9 { for c in 0..<9 {
            guard cands[r][c].count == 3 else { continue }
            let pivot: Pos = (r, c); let pc = cands[r][c]
            let wings = bivalue.filter { seesEachOther(pivot, $0) && cands[$0.row][$0.col].isSubset(of: pc) }
            for combo in combinations(wings, 2) {
                let (w1, w2) = (combo[0], combo[1])
                guard cands[w1.row][w1.col].union(cands[w2.row][w2.col]) == pc else { continue }
                let common = cands[w1.row][w1.col].intersection(cands[w2.row][w2.col])
                guard common.count == 1, let dig = common.first else { continue }
                var secondary: [Pos] = []
                for rr in 0..<9 { for cc in 0..<9 {
                    let p: Pos = (rr, cc)
                    guard cands[rr][cc].contains(dig) else { continue }
                    guard seesEachOther(p, pivot) && seesEachOther(p, w1) && seesEachOther(p, w2) else { continue }
                    guard !(p.row == pivot.row && p.col == pivot.col) && !(p.row == w1.row && p.col == w1.col) && !(p.row == w2.row && p.col == w2.col) else { continue }
                    secondary.append(p)
                }}
                guard !secondary.isEmpty else { continue }
                let reasoning: [String] = [
                    String(localized: "Pivot \(cellLabel(pivot)) contains \(digitList(Array(pc)))."),
                    String(localized: "Wings \(cellLabel(w1)) and \(cellLabel(w2)) together cover the same three digits and both include \(dig)."),
                    String(localized: "Any common peer of the pivot and both wings sees all ways the pattern can place \(dig): \(cellList(secondary))."),
                    String(localized: "→ Eliminate \(dig) from those cells.")
                ]
                return makeHint(.xyzWing, digit: dig, primary: [pivot, w1, w2], secondary: secondary,
                                explanation: String(localized: "XYZ-Wing: the pivot and its two wings force \(dig) to appear inside the pattern, so common peers lose \(dig)."),
                                reasoning: reasoning)
            }
        }}
        return nil
    }
    
    private static func wxyzWing(cands: [[Set<Int>]]) -> HintResult? {
        let bivalue: [Pos] = (0..<9).flatMap { r in (0..<9).compactMap { c -> Pos? in cands[r][c].count == 2 ? (r, c) : nil } }
        for r in 0..<9 { for c in 0..<9 {
            guard cands[r][c].count == 4 else { continue }
            let pivot: Pos = (r, c); let pc = cands[r][c]
            let wings = bivalue.filter { seesEachOther(pivot, $0) && cands[$0.row][$0.col].isSubset(of: pc) }
            guard wings.count >= 3 else { continue }
            for combo in combinations(wings, 3) {
                let union = combo.reduce(Set<Int>()) { $0.union(cands[$1.row][$1.col]) }
                guard union == pc else { continue }
                let restricted = combo.reduce(pc) { $0.intersection(cands[$1.row][$1.col]) }
                guard restricted.count == 1, let rDigit = restricted.first else { continue }
                let allFour = [pivot] + combo
                var secondary: [Pos] = []
                for rr in 0..<9 { for cc in 0..<9 {
                    let p: Pos = (rr, cc)
                    guard cands[rr][cc].contains(rDigit) else { continue }
                    guard allFour.allSatisfy({ seesEachOther(p, $0) }) else { continue }
                    guard !allFour.contains(where: { $0.row == rr && $0.col == cc }) else { continue }
                    secondary.append(p)
                }}
                guard !secondary.isEmpty else { continue }
                let reasoning: [String] = [
                    String(localized: "Pivot \(cellLabel(pivot)) and wings \(cellList(combo)) together cover digits \(digitList(Array(pc)))."),
                    String(localized: "Candidate \(rDigit) is restricted across the whole WXYZ-Wing pattern."),
                    String(localized: "Any cell that sees all four highlighted cells cannot contain \(rDigit): \(cellList(secondary))."),
                    String(localized: "→ Eliminate \(rDigit) from those cells.")
                ]
                return makeHint(.wxyzWing, digit: rDigit, primary: allFour, secondary: secondary,
                                explanation: String(localized: "WXYZ-Wing: the highlighted pattern forces \(rDigit) to stay inside it, so common peers lose \(rDigit)."),
                                reasoning: reasoning)
            }
        }}
        return nil
    }
    
    // MARK: - Palier 7: AIC, Forcing Chains
    
    private static func aic(cands: [[Set<Int>]]) -> HintResult? {
        func nodeId(_ cell: Int, _ digit: Int) -> Int { cell * 10 + digit }
        var adj: [Int: Set<Int>] = [:]
        for unit in allUnits {
            for digit in 1...9 {
                let places = unit.filter { cands[$0.row][$0.col].contains(digit) }
                guard places.count == 2 else { continue }
                let i0 = places[0].row*9 + places[0].col
                let i1 = places[1].row*9 + places[1].col
                let (n0, n1) = (nodeId(i0, digit), nodeId(i1, digit))
                adj[n0, default: []].insert(n1)
                adj[n1, default: []].insert(n0)
            }
        }
        for r in 0..<9 { for c in 0..<9 {
            guard cands[r][c].count == 2 else { continue }
            let arr = cands[r][c].sorted(); let cell = r*9+c
            let (n0, n1) = (nodeId(cell, arr[0]), nodeId(cell, arr[1]))
            adj[n0, default: []].insert(n1)
            adj[n1, default: []].insert(n0)
        }}
        guard !adj.isEmpty else { return nil }
        var colored: [Int: Int] = [:]
        for start in adj.keys where colored[start] == nil {
            var queue = [start]; colored[start] = 0; var qi = 0
            while qi < queue.count {
                let node = queue[qi]; qi += 1
                for nb in adj[node, default: []] where colored[nb] == nil {
                    colored[nb] = 1 - colored[node]!; queue.append(nb)
                }
            }
            let component = queue
            let grp0 = component.filter { colored[$0] == 0 }
            let grp1 = component.filter { colored[$0] == 1 }
            for (grpIdx, grp) in [grp0, grp1].enumerated() {
                for combo in combinations(grp, 2) {
                    let (n0, n1) = (combo[0], combo[1])
                    let (cell0, d0) = (n0/10, n0%10)
                    let (cell1, d1) = (n1/10, n1%10)
                    let (p0, p1) = (Pos(row: cell0/9, col: cell0%9), Pos(row: cell1/9, col: cell1%9))
                    guard cell0 == cell1 || (d0 == d1 && seesEachOther(p0, p1)) else { continue }
                    let other = uniquePositions((grpIdx == 0 ? grp1 : grp0).map { Pos(row: ($0/10)/9, col: ($0/10)%9) })
                    let elim = uniquePositions(grp.map { Pos(row: ($0/10)/9, col: ($0/10)%9) })
                    if !other.isEmpty {
                        let contradictionDescription: String = {
                            if cell0 == cell1 {
                                return String(localized: "the same color would force two candidates in \(cellLabel(p0)) at once")
                            }
                            return String(localized: "candidate \(d0) would be true in both \(cellLabel(p0)) and \(cellLabel(p1)), which see each other")
                        }()
                        let eliminations = grp.map { node in
                            let cell = node / 10
                            return (row: cell / 9, col: cell % 9, digit: node % 10)
                        }
                        let reasoning: [String] = [
                            String(localized: "Build the alternating chain from strong and weak links."),
                            String(localized: "One color causes a contradiction: \(contradictionDescription)."),
                            String(localized: "So the opposite color must be true in \(cellList(other))."),
                            String(localized: "→ Eliminate the candidates belonging to the contradictory color.")
                        ]
                        return makeHint(.aic, digit: nil, primary: other, secondary: elim,
                                        explanation: String(localized: "Alternating Inference Chain: one color contradicts itself, so the opposite color is forced."),
                                        reasoning: reasoning,
                                        eliminations: eliminations)
                    }
                }
            }
            let d0byDigit = Dictionary(grouping: grp0, by: { $0 % 10 })
            let d1byDigit = Dictionary(grouping: grp1, by: { $0 % 10 })
            for digit in 1...9 {
                guard let c0n = d0byDigit[digit], let c1n = d1byDigit[digit] else { continue }
                let pos0 = c0n.map { Pos(row: ($0/10)/9, col: ($0/10)%9) }
                let pos1 = c1n.map { Pos(row: ($0/10)/9, col: ($0/10)%9) }
                var secondary: [Pos] = []
                for r in 0..<9 { for c in 0..<9 {
                    guard cands[r][c].contains(digit) && colored[nodeId(r*9+c, digit)] == nil else { continue }
                    let p = Pos(row: r, col: c)
                    if pos0.contains(where: { seesEachOther(p, $0) }) && pos1.contains(where: { seesEachOther(p, $0) }) {
                        secondary.append(p)
                    }
                }}
                if !secondary.isEmpty {
                    let reasoning: [String] = [
                        String(localized: "Color the alternating chain for digit \(digit)."),
                        String(localized: "One color must contain the true \(digit) somewhere on the chain."),
                        String(localized: "Cells \(cellList(secondary)) see one candidate of each color, so they cannot contain \(digit)."),
                        String(localized: "→ Eliminate \(digit) from those cells.")
                    ]
                    return makeHint(.aic, digit: digit, primary: pos0 + pos1, secondary: secondary,
                                    explanation: String(localized: "Alternating Inference Chain on \(digit): any cell that sees both colors cannot keep \(digit)."),
                                    reasoning: reasoning)
                }
            }
        }
        return nil
    }
    
    private static func forcingChains(puzzle: Puzzle, cands: [[Set<Int>]]) -> HintResult? {
        let removed = removedCandidates(in: puzzle, from: cands)
        let bivalue: [(Pos, [Int])] = (0..<9).flatMap { r in
            (0..<9).compactMap { c -> (Pos, [Int])? in
                cands[r][c].count == 2 ? ((r, c), cands[r][c].sorted()) : nil
            }
        }
        var contradictionHint: HintResult?
        
        for (pivot, pivotCands) in bivalue {
            var branches: [ForcingBranchResult] = []
            var contradictions: [Bool] = []
            for tryDigit in pivotCands {
                let branch = forcingChainBranch(
                    puzzle: puzzle,
                    removed: removed,
                    pivot: pivot,
                    digit: tryDigit
                )
                branches.append(branch)
                contradictions.append(branch.contradiction)
            }
            let valid = zip(branches, contradictions).filter { !$0.1 }.map(\.0)
            if valid.count == pivotCands.count {
                for (pos, digit) in valid[0].placements where !(pos.row == pivot.row && pos.col == pivot.col) {
                    if valid.dropFirst().allSatisfy({ branch in
                        branch.placements.contains(where: { $0.0.row == pos.row && $0.0.col == pos.col && $0.1 == digit })
                    }) {
                        let secondary = Array(valid.flatMap { $0.placements.map(\.0) }.filter {
                            ($0.row != pos.row || $0.col != pos.col) && ($0.row != pivot.row || $0.col != pivot.col)
                        }.prefix(6))
                        let reasoning: [String] = [
                            String(localized: "Try each candidate at row \(pivot.row + 1), column \(pivot.col + 1)."),
                            String(localized: "Every valid branch forces \(digit) at row \(pos.row + 1), column \(pos.col + 1)."),
                            String(localized: "→ So row \(pos.row + 1), column \(pos.col + 1) must be \(digit).")
                        ]
                        return makeHint(
                            .forcingChains,
                            digit: digit,
                            primary: [pos],
                            secondary: secondary,
                            explanation: String(localized: "Forcing Chains: whatever the value at row \(pivot.row+1), column \(pivot.col+1), row \(pos.row+1), column \(pos.col+1) is always \(digit)."),
                            reasoning: reasoning,
                            eliminations: []
                        )
                    }
                }
            }
            
            guard contradictionHint == nil else { continue }
            for (i, isContra) in contradictions.enumerated() where isContra {
                let j = 1 - i
                guard j < pivotCands.count && !contradictions[j] else { continue }
                let eliminatedDigit = pivotCands[i]
                let contradictionCells = branches[i].placements.dropFirst().map(\.0)
                let reasoning = forcingContradictionReasoning(
                    pivot: pivot,
                    assumedDigit: eliminatedDigit,
                    contradictionPlacements: Array(branches[i].placements.dropFirst())
                )
                contradictionHint = makeHint(
                    .forcingChains,
                    digit: eliminatedDigit,
                    primary: contradictionCells.isEmpty ? [pivot] : contradictionCells,
                    secondary: [pivot],
                    explanation: String(localized: "Forcing Chains: assuming \(eliminatedDigit) at row \(pivot.row+1), column \(pivot.col+1) leads to a contradiction, so \(eliminatedDigit) can be eliminated from this cell."),
                    reasoning: reasoning,
                    eliminations: [(row: pivot.row, col: pivot.col, digit: eliminatedDigit)]
                )
                break
            }
        }
        return contradictionHint
    }
    
    private static func forcingChainBranch(
        puzzle: Puzzle,
        removed: Set<CandKey>,
        pivot: Pos,
        digit: Int
    ) -> ForcingBranchResult {
        var branchPuzzle = puzzle.settingValue(digit, row: pivot.row, col: pivot.col)
        var placements: [(Pos, Int)] = [(pivot, digit)]
        
        while true {
            let branchCands = computeCandidates(in: branchPuzzle, removing: removed)
            guard !hasCandidateContradiction(in: branchPuzzle, cands: branchCands) else {
                return ForcingBranchResult(placements: placements, contradiction: true)
            }
            
            if let single = forcingChainSinglePlacement(puzzle: branchPuzzle, cands: branchCands) {
                branchPuzzle = branchPuzzle.settingValue(single.digit, row: single.pos.row, col: single.pos.col)
                placements.append((single.pos, single.digit))
                continue
            }
            
            return ForcingBranchResult(placements: placements, contradiction: false)
        }
    }
    
    private static func hasCandidateContradiction(in puzzle: Puzzle, cands: [[Set<Int>]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 where puzzle.cells[row][col].value == nil {
                if cands[row][col].isEmpty {
                    return true
                }
            }
        }
        
        for unit in allUnits {
            for digit in 1...9 {
                let alreadyPlaced = unit.contains { puzzle.cells[$0.row][$0.col].value == digit }
                if alreadyPlaced {
                    continue
                }
                
                let possibleCells = unit.filter { puzzle.cells[$0.row][$0.col].value == nil && cands[$0.row][$0.col].contains(digit) }
                if possibleCells.isEmpty {
                    return true
                }
            }
        }
        
        return false
    }
    
    private static func forcingChainSinglePlacement(
        puzzle: Puzzle,
        cands: [[Set<Int>]]
    ) -> (pos: Pos, digit: Int)? {
        if let hint = nakedSingle(puzzle: puzzle, cands: cands),
           let digit = hint.digit,
           let pos = hint.primaryCells.first {
            return ((row: pos.row, col: pos.col), digit)
        }
        
        if let hint = hiddenSingle(puzzle: puzzle, cands: cands),
           let digit = hint.digit,
           let pos = hint.primaryCells.first {
            return ((row: pos.row, col: pos.col), digit)
        }
        
        return nil
    }
    
    private static func forcingContradictionReasoning(
        pivot: Pos,
        assumedDigit: Int,
        contradictionPlacements: [(Pos, Int)]
    ) -> [String] {
        var steps = [
            String(localized: "Assume \(assumedDigit) at row \(pivot.row + 1), column \(pivot.col + 1).")
        ]
        
        let preview = contradictionPlacements.prefix(4).map { placement in
            String(localized: "row \(placement.0.row + 1), column \(placement.0.col + 1) = \(placement.1)")
        }
        if !preview.isEmpty {
            steps.append(String(localized: "This forces: \(preview.joined(separator: ", "))."))
        }
        if contradictionPlacements.count > preview.count {
            steps.append(String(localized: "The chain keeps propagating until the grid becomes impossible."))
        } else {
            steps.append(String(localized: "That chain makes the grid impossible."))
        }
        steps.append(String(localized: "→ Eliminate \(assumedDigit) from row \(pivot.row + 1), column \(pivot.col + 1)."))
        
        return steps
    }
}
