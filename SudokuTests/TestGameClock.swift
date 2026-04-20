import Foundation
@testable import Sudoku

@MainActor
final class TestGameClock: GameClock {
    private(set) var isRunning = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var lastInterval: TimeInterval?
    private var onTick: (@MainActor () -> Void)?
    
    func start(interval: TimeInterval, onTick: @escaping @MainActor () -> Void) {
        startCount += 1
        isRunning = true
        lastInterval = interval
        self.onTick = onTick
    }
    
    func stop() {
        stopCount += 1
        isRunning = false
        onTick = nil
    }
    
    func tick() {
        onTick?()
    }
}
