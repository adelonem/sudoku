import Testing
import Foundation
@testable import Sudoku

struct CellTests {
    @Test func isFixedReturnsTrueForFixed() {
        #expect(Cell.fixed(5).isFixed == true)
    }
    
    @Test func isFixedReturnsFalseForOtherCases() {
        #expect(Cell.guess(5).isFixed == false)
        #expect(Cell.notes([1, 2]).isFixed == false)
        #expect(Cell.empty.isFixed == false)
    }
    
    @Test func isGuessReturnsTrueForGuess() {
        #expect(Cell.guess(3).isGuess == true)
    }
    
    @Test func isGuessReturnsFalseForOtherCases() {
        #expect(Cell.fixed(3).isGuess == false)
        #expect(Cell.notes([1, 2]).isGuess == false)
        #expect(Cell.empty.isGuess == false)
    }
    
    @Test func valueReturnsIntForFixedAndGuess() {
        #expect(Cell.fixed(7).value == 7)
        #expect(Cell.guess(4).value == 4)
    }
    
    @Test func valueReturnsNilForNotesAndEmpty() {
        #expect(Cell.notes([1, 2]).value == nil)
        #expect(Cell.empty.value == nil)
    }
    
    @Test func encodesAndDecodesFixed() throws {
        let cell = Cell.fixed(9)
        let data = try JSONEncoder().encode(cell)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded.value == 9)
        #expect(decoded.isFixed == true)
    }
    
    @Test func encodesAndDecodesGuess() throws {
        let cell = Cell.guess(3)
        let data = try JSONEncoder().encode(cell)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded.value == 3)
        #expect(decoded.isGuess == true)
    }
    
    @Test func encodesAndDecodesNotes() throws {
        let cell = Cell.notes([1, 4, 7])
        let data = try JSONEncoder().encode(cell)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        if case .notes(let candidates) = decoded {
            #expect(candidates == [1, 4, 7])
        } else {
            Issue.record("Expected .notes")
        }
    }
    
    @Test func encodesAndDecodesEmpty() throws {
        let cell = Cell.empty
        let data = try JSONEncoder().encode(cell)
        let decoded = try JSONDecoder().decode(Cell.self, from: data)
        #expect(decoded.value == nil)
        #expect(decoded.isFixed == false)
        #expect(decoded.isGuess == false)
    }
}
