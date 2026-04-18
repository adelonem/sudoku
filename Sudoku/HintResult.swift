//
//  HintResult.swift
//  Sudoku
//

/// Describes a single actionable hint: which technique applies, which cells are involved,
/// and what explanation to show the player.
struct HintResult {
    let technique: SudokuTechnique
    /// The digit the technique concerns, or nil for pure-elimination techniques.
    let digit: Int?
    /// Cells directly targeted by the technique (strong amber highlight).
    let primaryCells: [(row: Int, col: Int)]
    /// Context cells that justify the move (light amber highlight).
    let secondaryCells: [(row: Int, col: Int)]
    let title: String
    /// One-sentence summary of the technique.
    let explanation: String
    /// Step-by-step reasoning that explains *why* the technique applies here.
    let reasoning: [String]
    /// Which (row, col, digit) tuples this hint eliminates — used for chain detection.
    let eliminations: [(row: Int, col: Int, digit: Int)]
}
