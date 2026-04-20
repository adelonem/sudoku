import Foundation

@MainActor
protocol GameClock: AnyObject {
    var isRunning: Bool { get }
    func start(interval: TimeInterval, onTick: @escaping @MainActor () -> Void)
    func stop()
}

@MainActor
final class SystemGameClock: GameClock {
    private var timer: Timer?
    
    var isRunning: Bool {
        timer != nil
    }
    
    func start(interval: TimeInterval, onTick: @escaping @MainActor () -> Void) {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                onTick()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
