import Foundation
import Observation

@MainActor
@Observable
final class PuzzleViewModel {
    private(set) var puzzle: Puzzle
    private var possibilitiesPuzzle: Puzzle
    private(set) var showPossibilities = false
    var selectedRow: Int?
    var selectedCol: Int?
    private(set) var selectedDigit: Int?
    private(set) var isSolved = false
    var puzzleNumber: Int?
    var puzzleDifficulty: String?
    var puzzleTechniques: [String] = []
    private(set) var highlightedDigit: Int?
    private(set) var errorCount = 0
    private(set) var hintCount = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var celebrationDelays: [Int: Double] = [:]
    private(set) var activeHintChain: [HintResult] = []
    private(set) var activeHintIndex = 0
    private(set) var hintBasePuzzle: Puzzle?
    private(set) var isAutoCompleting = false
    private(set) var isPuzzleTrivial = false
    private(set) var completedPuzzles: [CompletedPuzzle] = []
    
    private static let maxUndoDepth = 1_000
    
    private let savedGameStore: any SavedGameStoring
    private let completedPuzzleStore: any CompletedPuzzleStoring
    private let catalogLoader: any PuzzleCatalogLoading
    private let gameClock: any GameClock
    
    private var autoFillWorkItem: DispatchWorkItem?
    private var autoFillGeneration = 0
    private var undoStack: [(puzzle: Puzzle, possibilities: Puzzle)] = []
    private var solution: [Int]?
    private var digitCounts = Array(repeating: 0, count: 10)
    private var catalog: PuzzleCatalog?
    private var hasLoaded = false
    
    var activeHint: HintResult? {
        activeHintChain.isEmpty ? nil : activeHintChain[activeHintIndex]
    }
    
    var isShowingHint: Bool {
        !activeHintChain.isEmpty
    }
    
    var canGoPrevHint: Bool {
        activeHintIndex > 0
    }
    
    var canGoNextHint: Bool {
        activeHintIndex < activeHintChain.count - 1
    }
    
    var hintAppliedActionCount: Int {
        activeHintIndex
    }
    
    var hintPreviewPuzzle: Puzzle? {
        guard let hintBasePuzzle else { return nil }
        return PuzzleCandidatesBuilder.hintPreview(
            from: hintBasePuzzle,
            applying: Array(activeHintChain.prefix(activeHintIndex))
        )
    }
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var canRevealSolution: Bool {
        guard let row = selectedRow, let col = selectedCol else { return false }
        return !currentPuzzle.cells[row][col].isFixed && currentPuzzle.cells[row][col].value == nil
    }
    
    var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var currentPuzzle: Puzzle {
        get { showPossibilities ? possibilitiesPuzzle : puzzle }
        set {
            if showPossibilities {
                possibilitiesPuzzle = newValue
            } else {
                puzzle = newValue
            }
        }
    }
    
    init(puzzle: Puzzle, dependencies: PuzzleViewModelDependencies? = nil) {
        let dependencies = dependencies ?? .live
        self.puzzle = puzzle
        self.possibilitiesPuzzle = puzzle
        self.savedGameStore = dependencies.savedGameStore
        self.completedPuzzleStore = dependencies.completedPuzzleStore
        self.catalogLoader = dependencies.catalogLoader
        self.gameClock = dependencies.gameClock
    }
    
    // MARK: - Loading
    
    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadCatalog()
        loadSavedGameIfAvailable()
        possibilitiesPuzzle = puzzle
        solution = PuzzleSolver.solve(puzzle)
        recomputeDigitCounts()
        recomputeIsSolved(recordCompletion: false)
        completedPuzzles = completedPuzzleStore.loadAll()
        startTimer()
    }
    
    @discardableResult
    func loadGameByID(_ id: Int) -> Bool {
        guard let entry = catalog?.entry(byID: id) else { return false }
        loadEntry(entry)
        resetState()
        return true
    }
    
    func loadEntry(_ entry: CatalogEntry) {
        puzzle = entry.puzzle
        possibilitiesPuzzle = entry.puzzle
        puzzleNumber = entry.id
        puzzleDifficulty = entry.difficulty
        puzzleTechniques = entry.techniques
    }
    
    func newGame(difficulty: String? = nil) {
        guard let catalog else { return }
        let entries = availableEntries(in: catalog, matching: difficulty)
        let candidates = entries.filter { $0.id != puzzleNumber }
        
        if let entry = candidates.randomElement() ?? entries.randomElement() {
            loadEntry(entry)
        }
        resetState()
    }
    
    func restartGame() {
        puzzle = puzzle.clearingEditableCells()
        resetState()
    }
    
    private func availableEntries(in catalog: PuzzleCatalog, matching difficulty: String?) -> [CatalogEntry] {
        guard let difficulty else { return catalog.entries }
        let filteredEntries = catalog.entries(forDifficulty: difficulty)
        return filteredEntries.isEmpty ? catalog.entries : filteredEntries
    }
    
    // MARK: - Selection
    
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
    
    func remainingCount(for digit: Int) -> Int {
        guard (1...Puzzle.size).contains(digit) else { return 0 }
        return max(0, Puzzle.size - digitCounts[digit])
    }
    
    // MARK: - Grid State
    
    func highlight(row: Int, col: Int) -> CellHighlight {
        if let selectedRow, let selectedCol, row == selectedRow, col == selectedCol {
            return .selected
        }
        
        if let highlightedDigit, let digit = currentPuzzle.cells[row][col].value, highlightedDigit == digit {
            return .digitMatch
        }
        
        if hasConflict(atRow: row, col: col) {
            return .conflict
        }
        
        if let activeHint {
            if activeHint.primaryCells.contains(where: { $0.row == row && $0.col == col }) {
                return .hintPrimary
            }
            
            if activeHint.secondaryCells.contains(where: { $0.row == row && $0.col == col }) {
                return .hintSecondary
            }
        }
        
        if let selectedRow, let selectedCol {
            if row == selectedRow || col == selectedCol {
                return .peer
            }
            
            if row / Puzzle.blockSize == selectedRow / Puzzle.blockSize,
               col / Puzzle.blockSize == selectedCol / Puzzle.blockSize {
                return .peer
            }
        }
        
        return .none
    }
    
    func invalidNotes(row: Int, col: Int) -> Set<Int> {
        let notes = currentPuzzle.cells[row][col].notes
        guard !notes.isEmpty else { return [] }
        let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: currentPuzzle)
        return notes.subtracting(candidates)
    }
    
    func hasConflict(atRow row: Int, col: Int) -> Bool {
        let cell = currentPuzzle.cells[row][col]
        
        if case .guess(let digit) = cell,
           let solution,
           solution[row * Puzzle.size + col] != digit {
            return true
        }
        
        return PuzzleSolver.hasConflict(atRow: row, col: col, in: currentPuzzle)
    }
    
    // MARK: - Hints
    
    func requestHint() {
        guard !isAutoCompleting else { return }
        
        if isShowingHint {
            clearHint()
            return
        }
        
        let basePuzzle = puzzle
        let chain = HintDetector.findHintChain(in: basePuzzle)
        
        guard !chain.isEmpty else {
            revealSolution()
            return
        }
        
        hintBasePuzzle = basePuzzle
        activeHintChain = chain
        activeHintIndex = 0
        highlightedDigit = chain[0].digit
        hintCount += 1
        persistState()
    }
    
    func clearHint() {
        hintBasePuzzle = nil
        activeHintChain = []
        activeHintIndex = 0
        
        if let selectedRow, let selectedCol {
            highlightedDigit = currentPuzzle.cells[selectedRow][selectedCol].value ?? selectedDigit
        } else {
            highlightedDigit = selectedDigit
        }
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
    
    // MARK: - Editing
    
    func toggleNote(_ digit: Int) {
        guard !isAutoCompleting else { return }
        guard let selectedRow, let selectedCol else { return }
        guard !currentPuzzle.cells[selectedRow][selectedCol].isFixed else { return }
        guard !currentPuzzle.cells[selectedRow][selectedCol].isGuess else { return }
        
        clearHint()
        pushUndo()
        currentPuzzle = currentPuzzle.togglingNote(digit, row: selectedRow, col: selectedCol)
        persistState()
    }
    
    func placeDigit(_ digit: Int) {
        guard !isAutoCompleting else { return }
        guard let selectedRow, let selectedCol else { return }
        guard !currentPuzzle.cells[selectedRow][selectedCol].isFixed else { return }
        guard !currentPuzzle.cells[selectedRow][selectedCol].isGuess else { return }
        
        clearHint()
        pushUndo()
        setDigit(digit, row: selectedRow, col: selectedCol)
        highlightedDigit = digit
        
        if hasConflict(atRow: selectedRow, col: selectedCol) {
            errorCount += 1
        } else {
            checkZoneCompletion(row: selectedRow, col: selectedCol)
            updateTrivialPuzzleState()
        }
        
        refreshNotes()
        persistState()
    }
    
    func deleteCell() {
        guard !isAutoCompleting else { return }
        guard let selectedRow, let selectedCol else { return }
        guard !currentPuzzle.cells[selectedRow][selectedCol].isFixed else { return }
        
        clearHint()
        pushUndo()
        
        if currentPuzzle.cells[selectedRow][selectedCol].isGuess {
            puzzle = puzzle.clearingCell(row: selectedRow, col: selectedCol)
            possibilitiesPuzzle = possibilitiesPuzzle.clearingCell(row: selectedRow, col: selectedCol)
        } else {
            currentPuzzle = currentPuzzle.clearingCell(row: selectedRow, col: selectedCol)
        }
        
        highlightedDigit = nil
        refreshNotes()
        persistState()
    }
    
    func revealSolution() {
        guard !isAutoCompleting else { return }
        guard let selectedRow, let selectedCol, let solution else { return }
        guard !currentPuzzle.cells[selectedRow][selectedCol].isFixed else { return }
        
        clearHint()
        
        let solutionDigit = solution[selectedRow * Puzzle.size + selectedCol]
        hintCount += 1
        pushUndo()
        setDigit(solutionDigit, row: selectedRow, col: selectedCol)
        highlightedDigit = solutionDigit
        checkZoneCompletion(row: selectedRow, col: selectedCol)
        updateTrivialPuzzleState()
        refreshNotes()
        persistState()
    }
    
    func togglePossibilities() {
        guard !isAutoCompleting else { return }
        
        showPossibilities.toggle()
        
        if showPossibilities {
            possibilitiesPuzzle = PuzzleCandidatesBuilder.possibilities(for: puzzle)
        }
    }
    
    func undo() {
        clearHint()
        autoFillGeneration += 1
        autoFillWorkItem?.cancel()
        autoFillWorkItem = nil
        isAutoCompleting = false
        isPuzzleTrivial = false
        
        guard let previousState = undoStack.popLast() else { return }
        
        puzzle = previousState.puzzle
        possibilitiesPuzzle = previousState.possibilities
        
        if let selectedRow, let selectedCol {
            highlightedDigit = currentPuzzle.cells[selectedRow][selectedCol].value
        } else {
            highlightedDigit = nil
        }
        
        persistState()
    }
    
    // MARK: - Auto Complete
    
    func acceptAutoComplete() {
        guard isPuzzleTrivial else { return }
        isPuzzleTrivial = false
        startAutoComplete()
    }
    
    func dismissAutoComplete() {
        isPuzzleTrivial = false
    }
    
    // MARK: - Timer
    
    func startTimer() {
        guard !isSolved, !gameClock.isRunning else { return }
        
        gameClock.start(interval: 1) { [weak self] in
            self?.elapsedTime += 1
        }
    }
    
    func stopTimer() {
        gameClock.stop()
    }
    
    // MARK: - Celebration
    
    func isCelebrating(row: Int, col: Int) -> Bool {
        celebrationDelays[row * Puzzle.size + col] != nil
    }
    
    func celebrationDelay(row: Int, col: Int) -> Double? {
        celebrationDelays[row * Puzzle.size + col]
    }
    
    // MARK: - Persistence
    
    private func loadCatalog() {
        do {
            catalog = try catalogLoader.loadCatalog()
        } catch {
            catalog = nil
        }
    }
    
    private func loadSavedGameIfAvailable() {
        do {
            let savedGame = try savedGameStore.loadGame()
            puzzle = savedGame.puzzle
            puzzleNumber = savedGame.catalogID
            puzzleDifficulty = savedGame.difficulty
            puzzleTechniques = savedGame.techniques
            errorCount = savedGame.errorCount
            hintCount = savedGame.hintCount
            elapsedTime = savedGame.elapsedTime
        } catch {
            if let entry = catalog?.randomEntry() {
                loadEntry(entry)
            }
        }
    }
    
    private func persistState() {
        recomputeDigitCounts()
        recomputeIsSolved()
        
        guard let puzzleNumber, let puzzleDifficulty else { return }
        
        let savedGame = SavedGame(
            catalogID: puzzleNumber,
            difficulty: puzzleDifficulty,
            techniques: puzzleTechniques,
            puzzle: puzzle,
            errorCount: errorCount,
            hintCount: hintCount,
            elapsedTime: elapsedTime
        )
        
        try? savedGameStore.saveGame(savedGame)
    }
    
    // MARK: - Internal State
    
    private func setDigit(_ digit: Int, row: Int, col: Int) {
        puzzle = puzzle.settingValue(digit, row: row, col: col)
        possibilitiesPuzzle = possibilitiesPuzzle.settingValue(digit, row: row, col: col)
    }
    
    private func refreshNotes() {
        puzzle = PuzzleCandidatesBuilder.prunedNotes(in: puzzle)
        possibilitiesPuzzle = PuzzleCandidatesBuilder.prunedNotes(in: possibilitiesPuzzle)
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
    
    private func pushUndo() {
        if undoStack.count >= Self.maxUndoDepth {
            undoStack.removeFirst()
        }
        
        undoStack.append((puzzle: puzzle, possibilities: possibilitiesPuzzle))
    }
    
    private func recomputeDigitCounts() {
        digitCounts = Array(repeating: 0, count: 10)
        
        for row in puzzle.cells {
            for cell in row {
                if let digit = cell.value {
                    digitCounts[digit] += 1
                }
            }
        }
    }
    
    private func recomputeIsSolved(recordCompletion: Bool = true) {
        guard puzzle.isFilled else {
            isSolved = false
            return
        }
        
        let wasSolved = isSolved
        isSolved = (0..<Puzzle.size).allSatisfy { row in
            (0..<Puzzle.size).allSatisfy { col in
                !PuzzleSolver.hasConflict(atRow: row, col: col, in: puzzle)
            }
        }
        
        guard recordCompletion, !wasSolved, isSolved,
              let puzzleNumber, let puzzleDifficulty else {
            return
        }
        
        stopTimer()
        completedPuzzleStore.recordCompletion(
            catalogID: puzzleNumber,
            difficulty: puzzleDifficulty,
            errorCount: errorCount,
            hintCount: hintCount,
            elapsedTime: elapsedTime
        )
        completedPuzzles = completedPuzzleStore.loadAll()
    }
    
    private func updateTrivialPuzzleState() {
        isPuzzleTrivial = puzzle.emptyCellCount <= Puzzle.size && PuzzleSolver.isTrivial(puzzle)
    }
    
    // MARK: - Auto Fill
    
    private func startAutoComplete() {
        isAutoCompleting = true
        showPossibilities = true
        rebuildPossibilities()
        undoStack.removeAll()
        autoFillStep(generation: autoFillGeneration)
    }
    
    private func rebuildPossibilities() {
        possibilitiesPuzzle = PuzzleCandidatesBuilder.possibilities(for: puzzle)
    }
    
    private func nextNakedSingle() -> (row: Int, col: Int, digit: Int)? {
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard puzzle.cells[row][col].value == nil else { continue }
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                if candidates.count == 1, let digit = candidates.first {
                    return (row, col, digit)
                }
            }
        }
        
        return nil
    }
    
    private func autoFillStep(generation: Int) {
        guard let nextPlacement = nextNakedSingle() else {
            showPossibilities = false
            selectedRow = nil
            selectedCol = nil
            highlightedDigit = nil
            persistState()
            isAutoCompleting = false
            autoFillWorkItem = nil
            return
        }
        
        selectedRow = nextPlacement.row
        selectedCol = nextPlacement.col
        highlightedDigit = nextPlacement.digit
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.autoFillGeneration == generation else { return }
            self.puzzle = self.puzzle.settingValue(nextPlacement.digit, row: nextPlacement.row, col: nextPlacement.col)
            self.checkZoneCompletion(row: nextPlacement.row, col: nextPlacement.col)
            self.rebuildPossibilities()
            self.autoFillStep(generation: generation)
        }
        
        autoFillWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    // MARK: - Celebration Helpers
    
    private func checkZoneCompletion(row: Int, col: Int) {
        guard let solution else { return }
        
        var completedCells: [(Int, Int)] = []
        
        if isZoneCorrectlyCompleted(positions: (0..<Puzzle.size).map { (row, $0) }, solution: solution) {
            for currentCol in 0..<Puzzle.size {
                completedCells.append((row, currentCol))
            }
        }
        
        if isZoneCorrectlyCompleted(positions: (0..<Puzzle.size).map { ($0, col) }, solution: solution) {
            for currentRow in 0..<Puzzle.size {
                completedCells.append((currentRow, col))
            }
        }
        
        let blockRow = (row / Puzzle.blockSize) * Puzzle.blockSize
        let blockCol = (col / Puzzle.blockSize) * Puzzle.blockSize
        let blockPositions = (blockRow..<blockRow + Puzzle.blockSize).flatMap { currentRow in
            (blockCol..<blockCol + Puzzle.blockSize).map { currentCol in
                (currentRow, currentCol)
            }
        }
        
        if isZoneCorrectlyCompleted(positions: blockPositions, solution: solution) {
            completedCells.append(contentsOf: blockPositions)
        }
        
        guard !completedCells.isEmpty else { return }
        
        let uniqueKeys = Set(completedCells.map { $0.0 * Puzzle.size + $0.1 })
        let delayStep = 0.5 / Double(max(uniqueKeys.count, 1))
        let sortedKeys = uniqueKeys.sorted { lhs, rhs in
            let lhsRow = lhs / Puzzle.size
            let lhsCol = lhs % Puzzle.size
            let rhsRow = rhs / Puzzle.size
            let rhsCol = rhs % Puzzle.size
            let lhsDistance = abs(lhsRow - row) + abs(lhsCol - col)
            let rhsDistance = abs(rhsRow - row) + abs(rhsCol - col)
            return lhsDistance < rhsDistance
        }
        
        celebrationDelays = Dictionary(uniqueKeysWithValues: sortedKeys.enumerated().map { item in
            let (index, key) = item
            return (key, Double(index) * delayStep)
        })
        
        let totalDuration = (Double(sortedKeys.count) * delayStep) + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.celebrationDelays = [:]
        }
    }
    
    private func isZoneCorrectlyCompleted(positions: [(Int, Int)], solution: [Int]) -> Bool {
        positions.allSatisfy { position in
            let (row, col) = position
            guard let value = puzzle.cells[row][col].value else { return false }
            return value == solution[row * Puzzle.size + col]
        }
    }
}
