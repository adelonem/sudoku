//
//  Game.swift
//  sudoku
//

import Observation

@Observable
class Game {
    private(set) var digitFirstDigit: Int?
    /// The digit to highlight across the grid, driven by the most recent user action.
    private(set) var highlightedDigit: Int?
    private(set) var isNoteMode = false
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var puzzle = Puzzle()
    private(set) var selectedCell: CellPosition?
    
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
    
    // MARK: - Mode toggles
    
    /// Toggles note-entry mode on or off.
    func toggleNoteMode() {
        isNoteMode.toggle()
    }
    
    /// Toggles digit-first mode. If `digit` is already active, deactivates the mode.
    func toggleDigitFirst(_ digit: Int? = nil) {
        if let digit, digitFirstDigit != digit {
            digitFirstDigit = digit
            highlightedDigit = digit
        } else {
            digitFirstDigit = nil
            highlightedDigit = nil
        }
    }
    
    // MARK: - Actions
    
    /// Selects a cell on the board. In digit-first mode, also places the active digit.
    func select(row: Int, col: Int) {
        selectedCell = CellPosition(row: row, col: col)
        if digitFirstDigit != nil {
            enterDigit(digitFirstDigit)
        }
        // The selected cell's digit takes priority for highlighting
        highlightedDigit = puzzle[row, col].digit ?? digitFirstDigit
    }
    
    /// Enters or toggles a digit (or note) in the currently selected cell, then saves.
    func enterDigit(_ number: Int?) {
        guard let cell = selectedCell else { return }
        guard !puzzle[cell].isClue else { return }
        // Block modification of cells that already contain a user-entered digit (use deleteCell to clear first)
        if case .userEntry = puzzle[cell] { return }
        
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
        puzzle[cell] = .empty
        refreshNotes()
        saveInBackground()
    }
    
    /// Fills all empty cells' notes with valid candidates based on the current grid state.
    func fillAllNotes() {
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
        digitFirstDigit = nil
        highlightedDigit = nil
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
    
    // MARK: - Private helpers
    
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
