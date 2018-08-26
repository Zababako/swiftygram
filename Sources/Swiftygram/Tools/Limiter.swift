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
        var limits: Set<Limit>
        let action: () -> Void
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
                    limiter.pipe[i].limits.remove(limit)

                    guard limiter.pipe[i].limits.isEmpty else { continue }

                    limiter.pipe[i].action()
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
        }

        queue.async {
            [limits] in
            self.pipe.append(WorkItem(limits: limits, action: action))
        }
    }
}