import Testing
import SwiftUI
@testable import Sudoku

struct CellHighlightTests {
    
    private static let accent = Color.blue
    
    // MARK: - All cases return a Color
    
    @Test func conflictReturnsColor() {
        let color = CellHighlight.conflict.color(accent: Self.accent)
        #expect(color == Style.background)
    }
    
    @Test func noneReturnsBackground() {
        let color = CellHighlight.none.color(accent: Self.accent)
        #expect(color == Style.background)
    }
    
    @Test func conflictAndNoneReturnSameColor() {
        let conflict = CellHighlight.conflict.color(accent: Self.accent)
        let none = CellHighlight.none.color(accent: Self.accent)
        #expect(conflict == none)
    }
    
    @Test func allCasesReturnNonNilColor() {
        let cases: [CellHighlight] = [.conflict, .digitMatch, .selected, .peer, .hintPrimary, .hintSecondary, .none]
        for highlight in cases {
            // Simply calling color should not crash
            _ = highlight.color(accent: Self.accent)
        }
    }
    
    // MARK: - Hint colors are accent-independent
    
    @Test func hintPrimaryIsSameRegardlessOfAccent() {
        let blue = CellHighlight.hintPrimary.color(accent: .blue)
        let red = CellHighlight.hintPrimary.color(accent: .red)
        #expect(blue == red)
    }
    
    @Test func hintSecondaryIsSameRegardlessOfAccent() {
        let blue = CellHighlight.hintSecondary.color(accent: .blue)
        let red = CellHighlight.hintSecondary.color(accent: .red)
        #expect(blue == red)
    }
}
