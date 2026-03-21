//
//  Game.swift
//  sudoku
//

import Foundation

@Observable
class Game {
    private(set) var puzzle = Puzzle()
    private(set) var selectedCell: (row: Int, col: Int)?

    /// Returns the display digit (1-9) at the given cell, or nil if empty.
    func digit(atRow row: Int, col: Int) -> Int? {
        puzzle[row, col].digit
    }

    /// Returns true if the cell contains an original clue that cannot be edited.
    func isClue(atRow row: Int, col: Int) -> Bool {
        puzzle[row, col].isClue
    }

    /// Selects a cell on the board.
    func select(row: Int, col: Int) {
        selectedCell = (row, col)
    }

    /// Sets the value of the currently selected cell and saves the puzzle.
    func setValue(_ number: Int?) {
        guard let cell = selectedCell else { return }
        guard !puzzle[cell.row, cell.col].isClue else { return }

        if let number {
            puzzle[cell.row, cell.col] = .userEntry(number)
        } else {
            puzzle[cell.row, cell.col] = .empty
        }
        Storage.save(puzzle)
    }

    /// Loads a random puzzle from the collection and saves it.
    func newGame() {
        puzzle = Storage.loadPuzzleCollection()?.randomElement() ?? Puzzle()
        selectedCell = nil
        Storage.save(puzzle)
    }

    /// Restores a previously saved puzzle from persistent storage.
    func load() {
        if let saved = Storage.load() {
            puzzle = saved
        }
    }
}
