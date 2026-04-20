import Testing
import Foundation
@testable import Sudoku

struct PuzzleViewModelTests {
    private static let savedGameJSON = #"""
    {"errorCount":1,"catalogID":3177,"techniques":["hidden_singles","naked_singles","naked_pairs","naked_triples","pointing_pairs","forcing_chains"],"difficulty":"diabolic","puzzle":{"cells":[[{"type":"empty"},{"type":"empty"},{"type":"empty"},{"value":7,"type":"fixed"},{"type":"empty"},{"value":3,"type":"fixed"},{"value":6,"type":"guess"},{"type":"empty"},{"type":"empty"}],[{"value":6,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"value":5,"type":"guess"},{"type":"empty"},{"value":4,"type":"guess"},{"type":"empty"},{"value":8,"type":"fixed"},{"type":"empty"}],[{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"},{"value":6,"type":"guess"},{"type":"empty"},{"value":1,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"type":"empty"}],[{"value":9,"type":"guess"},{"value":6,"type":"fixed"},{"value":4,"type":"fixed"},{"value":1,"type":"guess"},{"value":3,"type":"guess"},{"value":2,"type":"guess"},{"value":8,"type":"guess"},{"type":"empty"},{"type":"empty"}],[{"value":2,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"type":"empty"},{"value":5,"type":"guess"},{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"},{"value":3,"type":"fixed"}],[{"type":"empty"},{"value":5,"type":"fixed"},{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"value":1,"type":"fixed"},{"value":2,"type":"fixed"},{"type":"empty"}],[{"type":"empty"},{"type":"empty"},{"value":9,"type":"guess"},{"type":"empty"},{"type":"empty"},{"value":5,"type":"fixed"},{"value":2,"type":"fixed"},{"type":"empty"},{"type":"empty"}],[{"type":"empty"},{"value":7,"type":"fixed"},{"value":2,"type":"guess"},{"value":3,"type":"fixed"},{"value":6,"type":"fixed"},{"value":9,"type":"guess"},{"type":"empty"},{"type":"empty"},{"value":8,"type":"fixed"}],[{"type":"empty"},{"type":"empty"},{"value":6,"type":"guess"},{"value":2,"type":"guess"},{"value":1,"type":"fixed"},{"type":"empty"},{"type":"empty"},{"value":9,"type":"fixed"},{"type":"empty"}]]},"elapsedTime":128,"hintCount":0}
    """#
    
    private static let fallbackEntry = CatalogEntry(
        id: 42,
        difficulty: "medium",
        values: [
            [0, 4, 0, 0, 8, 0, 2, 0, 3],
            [5, 8, 0, 7, 2, 0, 0, 0, 0],
            [0, 0, 3, 6, 0, 0, 0, 0, 7],
            [0, 2, 0, 5, 3, 9, 0, 1, 0],
            [8, 5, 1, 0, 0, 0, 0, 4, 0],
            [6, 3, 0, 4, 0, 8, 0, 0, 0],
            [0, 9, 0, 8, 7, 6, 0, 0, 2],
            [3, 7, 2, 9, 4, 1, 6, 5, 8],
            [1, 0, 0, 3, 5, 0, 0, 0, 0]
        ],
        techniques: ["hidden_singles", "naked_singles"]
    )
    
    private static let almostSolvedEntry = CatalogEntry(
        id: 99,
        difficulty: "easy",
        values: [
            [0, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],
            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],
            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ],
        techniques: ["naked_singles"]
    )
    
    @MainActor
    @Test func hintPreviewAppliesEliminationsWithoutMutatingPuzzle() throws {
        let savedGame = try JSONDecoder().decode(SavedGame.self, from: Data(Self.savedGameJSON.utf8))
        let viewModel = PuzzleViewModel(
            puzzle: savedGame.puzzle,
            dependencies: try Self.makeDependencies()
        )
        
        viewModel.requestHint()
        
        #expect(viewModel.activeHintChain.count >= 2)
        guard let firstHint = viewModel.activeHint,
              let firstElimination = firstHint.eliminations.first else {
            Issue.record("Expected the first hint to eliminate at least one candidate")
            return
        }
        
        guard let initialPreview = viewModel.hintPreviewPuzzle else {
            Issue.record("Expected a hint preview puzzle")
            return
        }
        
        #expect(initialPreview.cells[firstElimination.row][firstElimination.col].notes.contains(firstElimination.digit))
        #expect(viewModel.puzzle.cells[firstElimination.row][firstElimination.col] == savedGame.puzzle.cells[firstElimination.row][firstElimination.col])
        
        viewModel.nextHint()
        
        guard let advancedPreview = viewModel.hintPreviewPuzzle else {
            Issue.record("Expected a hint preview puzzle after advancing")
            return
        }
        
        #expect(!advancedPreview.cells[firstElimination.row][firstElimination.col].notes.contains(firstElimination.digit))
        #expect(viewModel.puzzle.cells[firstElimination.row][firstElimination.col] == savedGame.puzzle.cells[firstElimination.row][firstElimination.col])
    }
    
    @MainActor
    @Test func loadUsesInjectedSavedGameAndStartsClockOnlyOnce() throws {
        let savedGame = SavedGame(
            catalogID: 7,
            difficulty: "hard",
            techniques: ["naked_pairs"],
            puzzle: Puzzle(values: Self.fallbackEntry.values).settingValue(1, row: 0, col: 0),
            errorCount: 3,
            hintCount: 2,
            elapsedTime: 45
        )
        let savedGameStore = TestSavedGameStore(loadResult: .success(savedGame))
        let completedPuzzleStore = TestCompletedPuzzleStore(
            entries: [
                CompletedPuzzle(
                    catalogID: 2,
                    difficulty: "easy",
                    completedAt: Date(timeIntervalSince1970: 1),
                    errorCount: 0,
                    hintCount: 0,
                    elapsedTime: 10
                )
            ]
        )
        let gameClock = TestGameClock()
        let dependencies = try Self.makeDependencies(
            savedGameStore: savedGameStore,
            completedPuzzleStore: completedPuzzleStore,
            catalogEntries: [Self.fallbackEntry],
            gameClock: gameClock
        )
        let viewModel = PuzzleViewModel(puzzle: .sample, dependencies: dependencies)
        
        viewModel.load()
        viewModel.load()
        
        #expect(viewModel.puzzleNumber == 7)
        #expect(viewModel.puzzleDifficulty == "hard")
        #expect(viewModel.errorCount == 3)
        #expect(viewModel.hintCount == 2)
        #expect(viewModel.elapsedTime == 45)
        #expect(viewModel.completedPuzzles.count == 1)
        #expect(gameClock.startCount == 1)
    }
    
    @MainActor
    @Test func loadFallsBackToCatalogWhenSavedGameIsUnavailable() throws {
        let dependencies = try Self.makeDependencies(catalogEntries: [Self.fallbackEntry])
        let viewModel = PuzzleViewModel(puzzle: .sample, dependencies: dependencies)
        
        viewModel.load()
        
        #expect(viewModel.puzzleNumber == Self.fallbackEntry.id)
        #expect(viewModel.puzzleDifficulty == Self.fallbackEntry.difficulty)
        #expect(viewModel.puzzleTechniques == Self.fallbackEntry.techniques)
        #expect(viewModel.puzzle.cells[0][1].value == 4)
    }
    
    @MainActor
    @Test func newGameCanFilterByDifficulty() throws {
        let hardEntry = CatalogEntry(
            id: 123,
            difficulty: "hard",
            values: Self.fallbackEntry.values,
            techniques: ["naked_pairs"]
        )
        let dependencies = try Self.makeDependencies(catalogEntries: [Self.almostSolvedEntry, hardEntry])
        let viewModel = PuzzleViewModel(puzzle: .sample, dependencies: dependencies)
        
        viewModel.load()
        viewModel.newGame(difficulty: "hard")
        
        #expect(viewModel.puzzleNumber == hardEntry.id)
        #expect(viewModel.puzzleDifficulty == hardEntry.difficulty)
        #expect(viewModel.puzzleTechniques == hardEntry.techniques)
    }
    
    @MainActor
    @Test func placingFinalDigitRecordsCompletionAndStopsClock() throws {
        let savedGameStore = TestSavedGameStore()
        let completedPuzzleStore = TestCompletedPuzzleStore()
        let gameClock = TestGameClock()
        let dependencies = try Self.makeDependencies(
            savedGameStore: savedGameStore,
            completedPuzzleStore: completedPuzzleStore,
            catalogEntries: [Self.almostSolvedEntry],
            gameClock: gameClock
        )
        let viewModel = PuzzleViewModel(puzzle: .sample, dependencies: dependencies)
        
        viewModel.load()
        viewModel.select(row: 0, col: 0)
        viewModel.placeDigit(5)
        
        #expect(viewModel.isSolved)
        #expect(gameClock.startCount == 1)
        #expect(gameClock.stopCount == 1)
        #expect(completedPuzzleStore.recordCalls.count == 1)
        #expect(completedPuzzleStore.recordCalls[0].catalogID == Self.almostSolvedEntry.id)
        #expect(completedPuzzleStore.recordCalls[0].difficulty == Self.almostSolvedEntry.difficulty)
        #expect(viewModel.completedPuzzles.count == 1)
        #expect(savedGameStore.savedGames.last?.puzzle.cells[0][0].value == 5)
    }
    
    @MainActor
    @Test func timerUsesInjectedClock() throws {
        let gameClock = TestGameClock()
        let viewModel = PuzzleViewModel(
            puzzle: .sample,
            dependencies: try Self.makeDependencies(gameClock: gameClock)
        )
        
        viewModel.startTimer()
        viewModel.startTimer()
        gameClock.tick()
        gameClock.tick()
        viewModel.stopTimer()
        
        #expect(viewModel.elapsedTime == 2)
        #expect(gameClock.startCount == 1)
        #expect(gameClock.stopCount == 1)
        #expect(gameClock.lastInterval == 1)
    }
    
    @MainActor
    @Test func togglePossibilitiesPreservesUndoHistory() throws {
        let dependencies = try Self.makeDependencies(catalogEntries: [Self.fallbackEntry])
        let viewModel = PuzzleViewModel(puzzle: .sample, dependencies: dependencies)
        
        viewModel.load()
        viewModel.select(row: 0, col: 0)
        viewModel.placeDigit(1)
        #expect(viewModel.canUndo)
        #expect(viewModel.puzzle.cells[0][0].value == 1)
        
        viewModel.togglePossibilities()
        #expect(viewModel.canUndo)
        
        viewModel.undo()
        
        #expect(viewModel.puzzle.cells[0][0].value == nil)
        #expect(!viewModel.canUndo)
    }
}

private extension PuzzleViewModelTests {
    @MainActor
    static func makeDependencies(
        savedGameStore: TestSavedGameStore? = nil,
        completedPuzzleStore: TestCompletedPuzzleStore? = nil,
        catalogEntries: [CatalogEntry] = [],
        gameClock: TestGameClock? = nil
    ) throws -> PuzzleViewModelDependencies {
        let savedGameStore = savedGameStore ?? TestSavedGameStore()
        let completedPuzzleStore = completedPuzzleStore ?? TestCompletedPuzzleStore()
        let gameClock = gameClock ?? TestGameClock()
        let catalogLoader: TestPuzzleCatalogLoader
        
        if catalogEntries.isEmpty {
            catalogLoader = TestPuzzleCatalogLoader(result: .failure(TestDoubleError.unavailable))
        } else {
            catalogLoader = TestPuzzleCatalogLoader(result: .success(try makeCatalog(entries: catalogEntries)))
        }
        
        return PuzzleViewModelDependencies(
            savedGameStore: savedGameStore,
            completedPuzzleStore: completedPuzzleStore,
            catalogLoader: catalogLoader,
            gameClock: gameClock
        )
    }
    
    static func makeCatalog(entries: [CatalogEntry]) throws -> PuzzleCatalog {
        let data = try JSONEncoder().encode(entries)
        return try PuzzleCatalog(dataStore: ReadOnlyInMemoryDataStore(data: data))
    }
}
