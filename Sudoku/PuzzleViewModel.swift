//
//  PuzzleViewModel.swift
//  Sudoku
//

import Foundation

@Observable
final class PuzzleViewModel {
    private(set) var puzzle: Puzzle
    private var possibilitiesPuzzle: Puzzle
    private(set) var showPossibilities: Bool = false
    var selectedRow: Int? = nil
    var selectedCol: Int? = nil
    private(set) var selectedDigit: Int? = nil
    private(set) var isSolved: Bool = false
    var puzzleNumber: Int? = nil
    var puzzleDifficulty: String? = nil
    var puzzleTechniques: [String] = []
    private(set) var highlightedDigit: Int? = nil
    private(set) var errorCount: Int = 0
    private(set) var hintCount: Int = 0
    private(set) var elapsedTime: TimeInterval = 0
    private var timer: Timer?
    
    /// Per-cell wave delay (in seconds) for the completion celebration animation.
    /// Key is `row * 9 + col`, value is the delay before that cell's animation starts.
    private(set) var celebrationDelays: [Int: Double] = [:]
    
    /// The currently active hint chain, or empty if none is displayed.
    private(set) var activeHintChain: [HintResult] = []
    private(set) var activeHintIndex: Int = 0
    
    var activeHint: HintResult? { activeHintChain.isEmpty ? nil : activeHintChain[activeHintIndex] }
    var isShowingHint: Bool { !activeHintChain.isEmpty }
    var canGoPrevHint: Bool { activeHintIndex > 0 }
    var canGoNextHint: Bool { activeHintIndex < activeHintChain.count - 1 }
    
    private(set) var isAutoCompleting: Bool = false
    private(set) var isPuzzleTrivial: Bool = false
    private var autoFillWorkItem: DispatchWorkItem?
    /// Incremented on cancel to invalidate in-flight async closures.
    private var autoFillGeneration: Int = 0
    
    /// Stack of previous puzzle states for undo support.
    /// Each entry stores `(puzzle, possibilitiesPuzzle)` so that undo restores both.
    private static let maxUndoDepth = 1000
    private var undoStack: [(Puzzle, Puzzle)] = []
    
    /// Cached solution grid computed from the puzzle's fixed clues only.
    private var solution: [Int]?
    
    /// Cached count of each placed digit (1–9). Index 0 is unused, indices 1–9 hold counts.
    private var digitCounts = Array(repeating: 0, count: 10)
    private var catalog: PuzzleCatalog?
    private let gameStore = GameStore(dataStore: FileDataStore(fileName: "savedGame.json"))
    private let completedStore = CompletedPuzzlesStore()
    private(set) var completedPuzzles: [CompletedPuzzle] = []
    
    /// The puzzle currently being displayed and edited.
    var currentPuzzle: Puzzle {
        get { showPossibilities ? possibilitiesPuzzle : puzzle }
        set {
            if showPossibilities {
                possibilitiesPuzzle = newValue
            } else {
                puzzle = newValue
            }
        }
    }
    
    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.possibilitiesPuzzle = puzzle
    }
    
    func loadEntry(_ entry: CatalogEntry) {
        self.puzzle = entry.puzzle
        self.possibilitiesPuzzle = entry.puzzle
        self.puzzleNumber = entry.id
        self.puzzleDifficulty = entry.difficulty
        self.puzzleTechniques = entry.techniques
    }
    
    func select(row: Int, col: Int) {
        guard !isAutoCompleting else { return }
        clearHint()
        selectedRow = row
        selectedCol = col
        
        if let value = currentPuzzle.cells[row][col].value {
            highlightedDigit = value
            selectedDigit = value
        }
    }
    
    func cell(row: Int, col: Int) -> Cell {
        currentPuzzle.cells[row][col]
    }
    
    /// Whether there is at least one action that can be undone.
    var canUndo: Bool { !undoStack.isEmpty }
    
    /// Returns true if revealing the solution is possible for the selected cell.
    var canRevealSolution: Bool {
        guard let row = selectedRow, let col = selectedCol else { return false }
        return !currentPuzzle.cells[row][col].isFixed && currentPuzzle.cells[row][col].value == nil
    }
    
    /// Formats elapsed time as MM:SS.
    var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Returns the count of remaining placements for a given digit.
    func remainingCount(for digit: Int) -> Int {
        max(0, Puzzle.size - digitCounts[digit])
    }
    
    /// Returns the highlight state of the cell at the given position.
    func highlight(row: Int, col: Int) -> CellHighlight {
        if let sr = selectedRow, let sc = selectedCol, row == sr && col == sc {
            return .selected
        }
        
        if let hd = highlightedDigit, let d = currentPuzzle.cells[row][col].value, hd == d {
            return .digitMatch
        }
        
        if hasConflict(atRow: row, col: col) { return .conflict }
        
        if let hint = activeHint {
            if hint.primaryCells.contains(where: { $0.row == row && $0.col == col }) { return .hintPrimary }
            if hint.secondaryCells.contains(where: { $0.row == row && $0.col == col }) { return .hintSecondary }
        }
        
        if let sr = selectedRow, let sc = selectedCol {
            if row == sr || col == sc { return .peer }
            if row / 3 == sr / 3 && col / 3 == sc / 3 { return .peer }
        }
        
        return .none
    }
    
    /// Requests a technique-based hint chain for the current puzzle state.
    /// Toggles off the current hint if one is already displayed.
    func requestHint() {
        guard !isAutoCompleting else { return }
        if isShowingHint { clearHint(); return }
        let chain = HintDetector.findHintChain(in: currentPuzzle)
        if !chain.isEmpty {
            activeHintChain = chain
            activeHintIndex = 0
            highlightedDigit = chain[0].digit
            hintCount += 1
        } else {
            revealSolution()
        }
    }
    
    func clearHint() {
        activeHintChain = []
        activeHintIndex = 0
    }
    
    func prevHint() {
        guard canGoPrevHint else { return }
        activeHintIndex -= 1
        highlightedDigit = activeHint?.digit
    }
    
    func nextHint() {
        guard canGoNextHint else { return }
        activeHintIndex += 1
        highlightedDigit = activeHint?.digit
    }
    
    /// Returns the set of note digits that conflict with placed values in peer cells.
    func invalidNotes(row: Int, col: Int) -> Set<Int> {
        let notes = currentPuzzle.cells[row][col].notes
        guard !notes.isEmpty else { return [] }
        let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: currentPuzzle)
        return notes.subtracting(candidates)
    }
    
    /// Returns whether the cell at the given position has a conflict.
    func hasConflict(atRow row: Int, col: Int) -> Bool {
        let cell = currentPuzzle.cells[row][col]
        if case .guess(let d) = cell,
           let solution,
           solution[row * Puzzle.size + col] != d {
            return true
        }
        return PuzzleSolver.hasConflict(atRow: row, col: col, in: currentPuzzle)
    }
    
    func selectDigit(_ digit: Int) {
        guard !isAutoCompleting else { return }
        if selectedDigit == digit {
            selectedDigit = nil
            highlightedDigit = nil
        } else {
            selectedDigit = digit
            highlightedDigit = digit
        }
    }
    
    func toggleNote(_ digit: Int) {
        guard !isAutoCompleting else { return }
        guard let row = selectedRow, let col = selectedCol else { return }
        guard !currentPuzzle.cells[row][col].isFixed else { return }
        if currentPuzzle.cells[row][col].isGuess { return }
        clearHint()
        pushUndo()
        currentPuzzle = currentPuzzle.togglingNote(digit, row: row, col: col)
        persistState()
    }
    
    func placeDigit(_ digit: Int) {
        guard !isAutoCompleting else { return }
        guard let row = selectedRow, let col = selectedCol else { return }
        guard !currentPuzzle.cells[row][col].isFixed else { return }
        if currentPuzzle.cells[row][col].isGuess { return }
        clearHint()
        pushUndo()
        puzzle = puzzle.settingValue(digit, row: row, col: col)
        possibilitiesPuzzle = possibilitiesPuzzle.settingValue(digit, row: row, col: col)
        highlightedDigit = digit
        if hasConflict(atRow: row, col: col) {
            errorCount += 1
        } else {
            checkZoneCompletion(row: row, col: col)
            let emptyCells = puzzle.cells.flatMap({ $0 }).filter({ $0.value == nil }).count
            if emptyCells <= 9 && PuzzleSolver.isTrivial(puzzle) {
                isPuzzleTrivial = true
            }
        }
        refreshNotes()
        persistState()
    }
    
    /// Called when the player taps the trivial-puzzle banner to accept auto-completion.
    func acceptAutoComplete() {
        guard isPuzzleTrivial else { return }
        isPuzzleTrivial = false
        autoComplete(from: 0, placedCol: 0)
    }
    
    /// Called when the player dismisses the trivial-puzzle banner.
    func dismissAutoComplete() {
        isPuzzleTrivial = false
    }
    
    func deleteCell() {
        guard !isAutoCompleting else { return }
        guard let row = selectedRow, let col = selectedCol else { return }
        guard !currentPuzzle.cells[row][col].isFixed else { return }
        clearHint()
        pushUndo()
        if currentPuzzle.cells[row][col].isGuess {
            puzzle = puzzle.clearingCell(row: row, col: col)
            possibilitiesPuzzle = possibilitiesPuzzle.clearingCell(row: row, col: col)
        } else {
            currentPuzzle = currentPuzzle.clearingCell(row: row, col: col)
        }
        highlightedDigit = nil
        refreshNotes()
        persistState()
    }
    
    func revealSolution() {
        guard !isAutoCompleting else { return }
        guard let row = selectedRow, let col = selectedCol, let solution else { return }
        guard !currentPuzzle.cells[row][col].isFixed else { return }
        clearHint()
        let solutionDigit = solution[row * Puzzle.size + col]
        hintCount += 1
        pushUndo()
        puzzle = puzzle.settingValue(solutionDigit, row: row, col: col)
        possibilitiesPuzzle = possibilitiesPuzzle.settingValue(solutionDigit, row: row, col: col)
        highlightedDigit = solutionDigit
        checkZoneCompletion(row: row, col: col)
        let emptyCells = puzzle.cells.flatMap({ $0 }).filter({ $0.value == nil }).count
        if emptyCells <= 9 && PuzzleSolver.isTrivial(puzzle) {
            isPuzzleTrivial = true
        }
        refreshNotes()
        persistState()
    }
    
    func togglePossibilities() {
        guard !isAutoCompleting else { return }
        showPossibilities.toggle()
        if showPossibilities {
            var cells = puzzle.cells
            for row in 0..<Puzzle.size {
                for col in 0..<Puzzle.size {
                    guard cells[row][col].value == nil else { continue }
                    let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                    cells[row][col] = candidates.isEmpty ? .empty : .notes(candidates)
                }
            }
            possibilitiesPuzzle = Puzzle(cells: cells)
        }
        undoStack.removeAll()
    }
    
    func newGame() {
        guard let catalog else { return }
        let candidates = catalog.entries.filter { $0.id != puzzleNumber }
        if let entry = candidates.randomElement() ?? catalog.entries.randomElement() {
            loadEntry(entry)
        }
        resetState()
    }
    
    /// Loads the puzzle with the given ID. Returns true if found, false otherwise.
    @discardableResult
    func loadGameByID(_ id: Int) -> Bool {
        guard let entry = catalog?.entry(byID: id) else { return false }
        loadEntry(entry)
        resetState()
        return true
    }
    
    func restartGame() {
        let cleared = Puzzle(cells: puzzle.cells.map { row in
            row.map { cell in
                cell.isFixed ? cell : .empty
            }
        })
        puzzle = cleared
        resetState()
    }
    
    func undo() {
        clearHint()
        autoFillGeneration += 1
        autoFillWorkItem?.cancel()
        autoFillWorkItem = nil
        isAutoCompleting = false
        isPuzzleTrivial = false
        guard let (previousPuzzle, previousPossibilities) = undoStack.popLast() else { return }
        puzzle = previousPuzzle
        possibilitiesPuzzle = previousPossibilities
        if let row = selectedRow, let col = selectedCol {
            highlightedDigit = currentPuzzle.cells[row][col].value
        } else {
            highlightedDigit = nil
        }
        persistState()
    }
    
    func load() {
        do {
            catalog = try PuzzleCatalog(dataStore: BundleDataStore(resource: "puzzles", withExtension: "json"))
        } catch { }
        
        do {
            let saved = try gameStore.loadGame()
            puzzle = saved.puzzle
            puzzleNumber = saved.catalogID
            puzzleDifficulty = saved.difficulty
            puzzleTechniques = saved.techniques
            errorCount = saved.errorCount
            hintCount = saved.hintCount
            elapsedTime = saved.elapsedTime
        } catch {
            if let catalog, let entry = catalog.entries.randomElement() {
                loadEntry(entry)
            }
        }
        
        possibilitiesPuzzle = puzzle
        solution = PuzzleSolver.solve(puzzle)
        recomputeDigitCounts()
        recomputeIsSolved(recordCompletion: false)
        completedPuzzles = completedStore.loadAll()
        startTimer()
    }
    
    private func autoComplete(from placedRow: Int, placedCol: Int) {
        isAutoCompleting = true
        showPossibilities = true
        rebuildPossibilities()
        undoStack.removeAll()
        autoFillStep(generation: autoFillGeneration)
    }
    
    /// Rebuilds possibilitiesPuzzle from the current puzzle state.
    private func rebuildPossibilities() {
        var cells = puzzle.cells
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard cells[row][col].value == nil else { continue }
                let cands = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                cells[row][col] = cands.isEmpty ? .empty : .notes(cands)
            }
        }
        possibilitiesPuzzle = Puzzle(cells: cells)
    }
    
    /// Finds the first empty cell with exactly one candidate in the current puzzle.
    private func nextNakedSingle() -> (row: Int, col: Int, digit: Int)? {
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard puzzle.cells[row][col].value == nil else { continue }
                let cands = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                if cands.count == 1, let digit = cands.first {
                    return (row, col, digit)
                }
            }
        }
        return nil
    }
    
    /// One step of the auto-fill loop: select the next cell, wait 0.5s, fill it, repeat.
    private func autoFillStep(generation: Int) {
        guard let (row, col, digit) = nextNakedSingle() else {
            showPossibilities = false
            selectedRow = nil
            selectedCol = nil
            highlightedDigit = nil
            persistState()
            isAutoCompleting = false
            autoFillWorkItem = nil
            return
        }
        
        selectedRow = row
        selectedCol = col
        highlightedDigit = digit
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.autoFillGeneration == generation else { return }
            self.puzzle = self.puzzle.settingValue(digit, row: row, col: col)
            self.checkZoneCompletion(row: row, col: col)
            self.rebuildPossibilities()
            self.autoFillStep(generation: generation)
        }
        autoFillWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func pushUndo() {
        if undoStack.count >= Self.maxUndoDepth {
            undoStack.removeFirst()
        }
        undoStack.append((puzzle, possibilitiesPuzzle))
    }
    
    private func recomputeDigitCounts() {
        digitCounts = Array(repeating: 0, count: 10)
        for row in puzzle.cells {
            for cell in row {
                if let d = cell.value {
                    digitCounts[d] += 1
                }
            }
        }
    }
    
    private func recomputeIsSolved(recordCompletion: Bool = true) {
        let allFilled = puzzle.cells.allSatisfy { row in
            row.allSatisfy { $0.value != nil }
        }
        guard allFilled else {
            isSolved = false
            return
        }
        let wasSolved = isSolved
        isSolved = (0..<Puzzle.size).allSatisfy { row in
            (0..<Puzzle.size).allSatisfy { col in
                !PuzzleSolver.hasConflict(atRow: row, col: col, in: puzzle)
            }
        }
        if recordCompletion, !wasSolved, isSolved,
           let number = puzzleNumber, let difficulty = puzzleDifficulty {
            stopTimer()
            completedStore.recordCompletion(catalogID: number, difficulty: difficulty, errorCount: errorCount, hintCount: hintCount, elapsedTime: elapsedTime)
            completedPuzzles = completedStore.loadAll()
        }
    }
    
    /// Removes invalidated notes from a puzzle based on its current grid state.
    private static func prunedNotes(in source: Puzzle) -> Puzzle {
        var cells = source.cells
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard case .notes(let existing) = cells[row][col] else { continue }
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: source)
                let remaining = existing.intersection(candidates)
                cells[row][col] = remaining.isEmpty ? .empty : .notes(remaining)
            }
        }
        return Puzzle(cells: cells)
    }
    
    /// Refreshes notes on both puzzles to remove invalidated digits.
    private func refreshNotes() {
        puzzle = Self.prunedNotes(in: puzzle)
        possibilitiesPuzzle = Self.prunedNotes(in: possibilitiesPuzzle)
    }
    
    private func resetState() {
        clearHint()
        autoFillGeneration += 1
        autoFillWorkItem?.cancel()
        autoFillWorkItem = nil
        isAutoCompleting = false
        isPuzzleTrivial = false
        selectedRow = nil
        selectedCol = nil
        selectedDigit = nil
        highlightedDigit = nil
        showPossibilities = false
        possibilitiesPuzzle = puzzle
        errorCount = 0
        hintCount = 0
        elapsedTime = 0
        stopTimer()
        undoStack.removeAll()
        solution = PuzzleSolver.solve(puzzle)
        persistState()
        startTimer()
    }
    
    func startTimer() {
        guard timer == nil, !isSolved else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Returns whether the cell at (row, col) is currently celebrating.
    func isCelebrating(row: Int, col: Int) -> Bool {
        celebrationDelays[row * Puzzle.size + col] != nil
    }
    
    /// Returns the wave delay for a celebrating cell, or nil if not celebrating.
    func celebrationDelay(row: Int, col: Int) -> Double? {
        celebrationDelays[row * Puzzle.size + col]
    }
    
    /// Checks if placing a digit at (row, col) completed any row, column, or block.
    /// If so, populates `celebrationDelays` with staggered delays to create a wave effect.
    private func checkZoneCompletion(row: Int, col: Int) {
        guard let solution else { return }
        
        var completedCells: [(Int, Int)] = []
        
        if isZoneCorrectlyCompleted(positions: (0..<Puzzle.size).map { (row, $0) }, solution: solution) {
            for c in 0..<Puzzle.size {
                completedCells.append((row, c))
            }
        }
        
        if isZoneCorrectlyCompleted(positions: (0..<Puzzle.size).map { ($0, col) }, solution: solution) {
            for r in 0..<Puzzle.size {
                completedCells.append((r, col))
            }
        }
        
        let blockRow = (row / Puzzle.blockSize) * Puzzle.blockSize
        let blockCol = (col / Puzzle.blockSize) * Puzzle.blockSize
        var blockPositions: [(Int, Int)] = []
        for r in blockRow..<blockRow + Puzzle.blockSize {
            for c in blockCol..<blockCol + Puzzle.blockSize {
                blockPositions.append((r, c))
            }
        }
        if isZoneCorrectlyCompleted(positions: blockPositions, solution: solution) {
            completedCells.append(contentsOf: blockPositions)
        }
        
        guard !completedCells.isEmpty else { return }
        
        let uniqueKeys = Set(completedCells.map { $0.0 * Puzzle.size + $0.1 })
        let delayStep = 0.5 / Double(max(uniqueKeys.count, 1))
        
        let sorted = uniqueKeys.sorted { a, b in
            let rA = a / Puzzle.size, cA = a % Puzzle.size
            let rB = b / Puzzle.size, cB = b % Puzzle.size
            let distA = abs(rA - row) + abs(cA - col)
            let distB = abs(rB - row) + abs(cB - col)
            return distA < distB
        }
        
        var delays: [Int: Double] = [:]
        for (index, key) in sorted.enumerated() {
            delays[key] = Double(index) * delayStep
        }
        celebrationDelays = delays
        
        let totalDuration = (Double(sorted.count) * delayStep) + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.celebrationDelays = [:]
        }
    }
    
    /// Returns true if every cell in the given positions is filled and matches the solution.
    /// Always reads from `puzzle` (not `currentPuzzle`) so it works even in possibilities mode.
    private func isZoneCorrectlyCompleted(positions: [(Int, Int)], solution: [Int]) -> Bool {
        positions.allSatisfy { (r, c) in
            guard let value = puzzle.cells[r][c].value else { return false }
            return value == solution[r * Puzzle.size + c]
        }
    }
    
    /// Recomputes cached state and persists the puzzle to disk.
    private func persistState() {
        recomputeDigitCounts()
        recomputeIsSolved()
        
        guard let number = puzzleNumber, let difficulty = puzzleDifficulty else { return }
        let saved = SavedGame(catalogID: number, difficulty: difficulty, techniques: puzzleTechniques, puzzle: puzzle, errorCount: errorCount, hintCount: hintCount, elapsedTime: elapsedTime)
        try? gameStore.saveGame(saved)
    }
}
