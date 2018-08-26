//
// Created by Zap on 25.08.2018.
//

import Foundation


/// Executes actions with respect for time density limits
final internal class Limiter {

    internal struct Limit: Hashable {
        let duration: TimeInterval
        let quantity: Int
    }

    private struct WorkItem {
        let action:    () -> Void
        let executed:  Bool
        var limitedBy: Set<Limit>
    }


    // MARK: - Private properties

    private let queue:  DispatchQueue
    private let limits: Set<Limit>
    private var timers: [DispatchSourceTimer] = []

    private var pipe: [WorkItem] = []


    // MARK: - Initialization / Deinitialization

    init(limits: Set<Limit> = [], targetQueue: DispatchQueue? = nil) {

        self.limits = limits
        self.queue  = DispatchQueue(label: "com.zababako.swiftygram.limiter", target: targetQueue)
        self.timers = limits.map {
            limit in

            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(deadline: .now(), repeating: limit.duration)
            source.setEventHandler {
                [weak self] in

                guard let limiter = self else { return }

                var indexesToClear: [Int] = []

                for i in 0..<min(limit.quantity, limiter.pipe.count) {
                    limiter.pipe[i].limitedBy.remove(limit)

                    guard limiter.pipe[i].limitedBy.isEmpty else { continue }

                    if !limiter.pipe[i].executed { limiter.pipe[i].action() }
                    indexesToClear.append(i)
                }

                indexesToClear.forEach { limiter.pipe.remove(at: $0) }
            }

            return source
        }

        timers.forEach { $0.resume() }
    }

    deinit {
        timers.forEach { $0.cancel() }
    }


    // MARK: - Limiter

    func execute(action: @escaping () -> Void) {

        if limits.isEmpty {
            queue.async { action() }
			return
        }

        queue.async {

            let currentLimits = self.pressingLimits()

            if currentLimits.isEmpty {
                action()
            }

            self.pipe.append(
               WorkItem(action: action, executed: currentLimits.isEmpty, limitedBy: currentLimits)
            )
        }
    }


    // MARK: - Private Methods

    func pressingLimits() -> Set<Limit> {
        return Set(limits.filter { $0.quantity < pipe.count })
    }
}
