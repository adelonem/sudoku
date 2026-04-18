import Testing
import Foundation
@testable import Sudoku

struct SudokuTechniqueTests {
    
    // MARK: - Raw values match puzzles.json keys
    
    @Test func rawValuesMatchJSONKeys() {
        #expect(SudokuTechnique.nakedSingles.rawValue == "naked_singles")
        #expect(SudokuTechnique.hiddenSingles.rawValue == "hidden_singles")
        #expect(SudokuTechnique.nakedPairs.rawValue == "naked_pairs")
        #expect(SudokuTechnique.nakedTriples.rawValue == "naked_triples")
        #expect(SudokuTechnique.nakedQuads.rawValue == "naked_quads")
        #expect(SudokuTechnique.pointingPairs.rawValue == "pointing_pairs")
        #expect(SudokuTechnique.hiddenPairs.rawValue == "hidden_pairs")
        #expect(SudokuTechnique.hiddenTriples.rawValue == "hidden_triples")
        #expect(SudokuTechnique.hiddenQuads.rawValue == "hidden_quads")
        #expect(SudokuTechnique.xWing.rawValue == "x_wing")
        #expect(SudokuTechnique.skyscraper.rawValue == "skyscraper")
        #expect(SudokuTechnique.simpleColoring.rawValue == "simple_coloring")
        #expect(SudokuTechnique.uniqueRectangle.rawValue == "unique_rectangle")
        #expect(SudokuTechnique.swordfish.rawValue == "swordfish")
        #expect(SudokuTechnique.jellyfish.rawValue == "jellyfish")
        #expect(SudokuTechnique.finnedXWing.rawValue == "finned_x_wing")
        #expect(SudokuTechnique.xyWing.rawValue == "xy_wing")
        #expect(SudokuTechnique.xyzWing.rawValue == "xyz_wing")
        #expect(SudokuTechnique.wxyzWing.rawValue == "wxyz_wing")
        #expect(SudokuTechnique.aic.rawValue == "aic")
        #expect(SudokuTechnique.forcingChains.rawValue == "forcing_chains")
    }
    
    // MARK: - Init from raw value
    
    @Test func initFromRawValueSucceeds() {
        #expect(SudokuTechnique(rawValue: "naked_singles") == .nakedSingles)
        #expect(SudokuTechnique(rawValue: "hidden_singles") == .hiddenSingles)
        #expect(SudokuTechnique(rawValue: "x_wing") == .xWing)
        #expect(SudokuTechnique(rawValue: "forcing_chains") == .forcingChains)
    }
    
    @Test func initFromInvalidRawValueReturnsNil() {
        #expect(SudokuTechnique(rawValue: "unknown") == nil)
        #expect(SudokuTechnique(rawValue: "") == nil)
        #expect(SudokuTechnique(rawValue: "Naked_Singles") == nil)
    }
    
    // MARK: - CaseIterable
    
    @Test func allCasesContainsAllTechniques() {
        #expect(SudokuTechnique.allCases.count == 21)
        #expect(SudokuTechnique.allCases.contains(.nakedSingles))
        #expect(SudokuTechnique.allCases.contains(.forcingChains))
    }
    
    // MARK: - Title
    
    @Test func titleIsNonEmpty() {
        for technique in SudokuTechnique.allCases {
            #expect(!technique.title.isEmpty)
        }
    }
    
    // MARK: - Difficulty
    
    @Test func difficultyIsNonEmpty() {
        for technique in SudokuTechnique.allCases {
            #expect(!technique.difficulty.isEmpty)
        }
    }
    
    @Test func easyTechniqueHasEasyDifficulty() {
        #expect(SudokuTechnique.nakedSingles.difficulty == String(localized: "Easy"))
    }
    
    @Test func mediumTechniqueHasMediumDifficulty() {
        #expect(SudokuTechnique.hiddenSingles.difficulty == String(localized: "Medium"))
    }
    
    @Test func hardTechniquesHaveHardDifficulty() {
        let hardTechniques: [SudokuTechnique] = [.nakedPairs, .nakedTriples, .nakedQuads, .pointingPairs]
        for technique in hardTechniques {
            #expect(technique.difficulty == String(localized: "Hard"))
        }
    }
    
    @Test func expertTechniquesHaveExpertDifficulty() {
        let expertTechniques: [SudokuTechnique] = [.hiddenPairs, .hiddenTriples, .hiddenQuads, .xWing, .skyscraper, .simpleColoring, .uniqueRectangle]
        for technique in expertTechniques {
            #expect(technique.difficulty == String(localized: "Expert"))
        }
    }
    
    @Test func extremeTechniquesHaveExtremeDifficulty() {
        let extremeTechniques: [SudokuTechnique] = [.swordfish, .jellyfish, .finnedXWing, .xyWing, .xyzWing, .wxyzWing]
        for technique in extremeTechniques {
            #expect(technique.difficulty == String(localized: "Extreme"))
        }
    }
    
    @Test func diabolicalTechniquesHaveDiabolicalDifficulty() {
        let diabolicalTechniques: [SudokuTechnique] = [.aic, .forcingChains]
        for technique in diabolicalTechniques {
            #expect(technique.difficulty == String(localized: "Diabolical"))
        }
    }
    
    // MARK: - localizedDifficulty function
    
    @Test func localizedDifficultyMapsKnownKeys() {
        #expect(localizedDifficulty("easy") == String(localized: "Easy"))
        #expect(localizedDifficulty("medium") == String(localized: "Medium"))
        #expect(localizedDifficulty("hard") == String(localized: "Hard"))
        #expect(localizedDifficulty("expert") == String(localized: "Expert"))
        #expect(localizedDifficulty("extreme") == String(localized: "Extreme"))
        #expect(localizedDifficulty("diabolical") == String(localized: "Diabolical"))
    }
    
    @Test func localizedDifficultyIsCaseInsensitive() {
        #expect(localizedDifficulty("Easy") == String(localized: "Easy"))
        #expect(localizedDifficulty("HARD") == String(localized: "Hard"))
        #expect(localizedDifficulty("Medium") == String(localized: "Medium"))
    }
    
    @Test func localizedDifficultyCapitalizesUnknown() {
        #expect(localizedDifficulty("custom") == "Custom")
        #expect(localizedDifficulty("super hard") == "Super Hard")
    }
}
