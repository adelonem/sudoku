//
//  Game.swift
//  sudoku
//

import Observation

/// Represents the locked action applied on each cell tap.
enum LockedAction: Equatable {
    case digit(Int)
    case erase
}

@Observable
class Game {
    private(set) var isLockedMode = false
    private(set) var lockedAction: LockedAction?
    private(set) var highlightedDigit: Int?
    private(set) var isNoteMode = false
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var puzzle = Puzzle()
    private(set) var selectedCell: CellPosition?
    
    /// Stack of previous puzzle states for undo support.
    private var undoStack: [Puzzle] = []
    
    /// Whether there is at least one action that can be undone.
    var canUndo: Bool { !undoStack.isEmpty }
    
    /// The current puzzle number, if any.
    var puzzleNumber: Int? { puzzle.number }
    
    /// The current puzzle difficulty label, if any.
    var puzzleDifficulty: String? { puzzle.difficulty }
    
    // MARK: - Cell queries
    
    /// Returns the display digit (1-9) at the given cell, or nil if empty.
    func digit(atRow row: Int, col: Int) -> Int? {
        puzzle[row, col].digit
    }
    
    /// Returns the notes for the given cell.
    func notes(atRow row: Int, col: Int) -> Set<Int> {
        puzzle[row, col].cellNotes
    }
    
    /// Returns true if the cell contains an original clue that cannot be edited.
    func isClue(atRow row: Int, col: Int) -> Bool {
        puzzle[row, col].isClue
    }
    
    /// Returns true if an entry at the given cell conflicts with another cell in the same row, column, or block.
    func hasConflict(atRow row: Int, col: Int) -> Bool {
        PuzzleSolver.hasConflict(atRow: row, col: col, in: puzzle)
    }
    
    /// Returns how many more times the given digit (1-9) needs to be placed.
    /// In a solved Sudoku each digit appears exactly 9 times.
    func remainingCount(for digit: Int) -> Int {
        let placed = puzzle.cells.filter { $0.digit == digit }.count
        return max(0, Puzzle.size - placed)
    }
    
    // MARK: - Mode toggles
    
    /// Toggles note-entry mode on or off.
    func toggleNoteMode() {
        isNoteMode.toggle()
    }
    
    /// Toggles the locked mode on or off when called without an action.
    /// When called with an action, sets or toggles it within the locked mode.
    func toggleLockedAction(_ action: LockedAction? = nil) {
        guard let action else {
            // No action provided: toggle the entire mode
            isLockedMode.toggle()
            if !isLockedMode {
                lockedAction = nil
                highlightedDigit = nil
            }
            return
        }
        // An action was provided: activate the mode and set/toggle the action
        isLockedMode = true
        if lockedAction == action {
            lockedAction = nil
            highlightedDigit = nil
        } else {
            lockedAction = action
            if case .digit(let d) = action {
                highlightedDigit = d
            } else {
                highlightedDigit = nil
            }
        }
    }
    
    // MARK: - Actions
    
    /// Selects a cell on the board. When a locked action is set, also applies it to the cell.
    func select(row: Int, col: Int) {
        selectedCell = CellPosition(row: row, col: col)
        switch lockedAction {
        case .digit(let d):
            enterDigit(d)
        case .erase:
            deleteCell()
        case nil:
            break
        }
        // The selected cell's digit takes priority for highlighting
        let activeDigit: Int? = if case .digit(let d) = lockedAction { d } else { nil }
        highlightedDigit = puzzle[row, col].digit ?? activeDigit
    }
    
    /// Enters or toggles a digit (or note) in the currently selected cell, then saves.
    func enterDigit(_ number: Int?) {
        guard let cell = selectedCell else { return }
        guard !puzzle[cell].isClue else { return }
        // Block modification of cells that already contain a user-entered digit (use deleteCell to clear first)
        if case .userEntry = puzzle[cell] { return }
        
        pushUndo()
        
        if isNoteMode {
            guard let number else {
                puzzle[cell] = .empty
                highlightedDigit = nil
                saveInBackground()
                return
            }
            var current = puzzle[cell].cellNotes
            let isAdding = !current.contains(number)
            current.formSymmetricDifference([number])
            puzzle[cell] = current.isEmpty ? .empty : .notes(current)
            highlightedDigit = isAdding ? number : nil
        } else {
            if let number {
                puzzle[cell] = .userEntry(number)
                highlightedDigit = number
            } else {
                puzzle[cell] = .empty
                highlightedDigit = nil
            }
            refreshNotes()
        }
        saveInBackground()
    }
    
    /// Deletes the content of the currently selected cell (digit and notes), then saves.
    func deleteCell() {
        guard let cell = selectedCell else { return }
        guard !puzzle[cell].isClue else { return }
        pushUndo()
        puzzle[cell] = .empty
        refreshNotes()
        saveInBackground()
    }
    
    /// Fills all empty cells' notes with valid candidates based on the current grid state.
    func fillAllNotes() {
        pushUndo()
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard puzzle[row, col].digit == nil else { continue }
                
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                puzzle[row, col] = candidates.isEmpty ? .empty : .notes(candidates)
            }
        }
        saveInBackground()
    }
    
    /// Loads a random puzzle from the collection (different from the current one) and saves it.
    func newGame() {
        let collection = Storage.loadPuzzleCollection() ?? []
        let candidates = collection.filter { $0.number != puzzle.number }
        puzzle = candidates.randomElement() ?? collection.randomElement() ?? Puzzle()
        selectedCell = nil
        isNoteMode = false
        isLockedMode = false
        lockedAction = nil
        highlightedDigit = nil
        undoStack.removeAll()
        saveInBackground()
    }
    
    /// Restores a previously saved puzzle from persistent storage.
    func load() {
        isLoading = true
        Task {
            let saved = await Storage.load()
            await MainActor.run {
                if let saved {
                    puzzle = saved
                }
                isLoading = false
            }
        }
    }
    
    /// Reverts the puzzle to the state before the last action.
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        puzzle = previous
        // Update highlighted digit based on the selected cell after undo
        if let cell = selectedCell {
            highlightedDigit = puzzle[cell].digit
        } else {
            highlightedDigit = nil
        }
        saveInBackground()
    }
    
    // MARK: - Private helpers
    
    /// Saves the current puzzle state onto the undo stack.
    private func pushUndo() {
        undoStack.append(puzzle)
    }
    
    /// Removes invalidated digits from existing notes based on the current grid state.
    /// Only removes digits that are no longer valid candidates — never adds new ones.
    private func refreshNotes() {
        for row in 0..<Puzzle.size {
            for col in 0..<Puzzle.size {
                guard case .notes(let existing) = puzzle[row, col] else { continue }
                
                let candidates = PuzzleSolver.candidates(atRow: row, col: col, in: puzzle)
                let updated = existing.intersection(candidates)
                puzzle[row, col] = updated.isEmpty ? .empty : .notes(updated)
            }
        }
    }
    
    /// Saves the puzzle asynchronously, updating `isSaving` while in progress.
    private func saveInBackground() {
        let snapshot = puzzle
        isSaving = true
        Task {
            await Storage.save(snapshot)
            await MainActor.run {
                isSaving = false
            }
        }
    }
}
