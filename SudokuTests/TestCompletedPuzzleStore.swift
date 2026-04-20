import Foundation
@testable import Sudoku

final class TestCompletedPuzzleStore: CompletedPuzzleStoring {
    struct RecordCall {
        let catalogID: Int
        let difficulty: String
        let errorCount: Int
        let hintCount: Int
        let elapsedTime: TimeInterval
    }
    
    private(set) var recordCalls: [RecordCall] = []
    var entries: [CompletedPuzzle]
    
    init(entries: [CompletedPuzzle] = []) {
        self.entries = entries
    }
    
    func loadAll() -> [CompletedPuzzle] {
        entries
    }
    
    func recordCompletion(
        catalogID: Int,
        difficulty: String,
        errorCount: Int,
        hintCount: Int,
        elapsedTime: TimeInterval
    ) {
        recordCalls.append(
            RecordCall(
                catalogID: catalogID,
                difficulty: difficulty,
                errorCount: errorCount,
                hintCount: hintCount,
                elapsedTime: elapsedTime
            )
        )
        
        entries.removeAll { $0.catalogID == catalogID }
        entries.append(
            CompletedPuzzle(
                catalogID: catalogID,
                difficulty: difficulty,
                completedAt: Date(timeIntervalSince1970: TimeInterval(recordCalls.count)),
                errorCount: errorCount,
                hintCount: hintCount,
                elapsedTime: elapsedTime
            )
        )
        entries.sort { $0.catalogID < $1.catalogID }
    }
}
