//
// Created by Zap on 22.08.2018.
//

import Foundation


/// Primitive implementation of no-more-then-one-per-second limit
/// More details on expected Telegram Bot API limits can be found
/// on [FAQ page](https://core.telegram.org/bots/faq#my-bot-is-hitting-limits-how-do-i-avoid-this)
final internal class APILimits: API {


    // MARK: - Private properties

    private let api:   API
    private let queue: DispatchQueue = DispatchQueue(label: "com.zababako.limits")
    private let clock: () -> TimeInterval

    private let minimalInterval: TimeInterval
    private var lastSentAt: TimeInterval = 0


    // MARK: - Initialization / Deinitialization

    internal init(
        api:             API,
        minimalInterval: TimeInterval,
        clock:           @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.api             = api
        self.minimalInterval = minimalInterval
        self.clock           = clock
    }


    // MARK: - API

    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void) {

        queue.async {
            [queue, api, minimalInterval, clock] in

            let now = clock()

            let interval = now - self.lastSentAt
            guard interval < minimalInterval else {
                api.send(request: request, onComplete: onComplete)
                self.lastSentAt = now
                return
            }

            let delay = (self.lastSentAt + minimalInterval) - now
            queue.asyncAfter(seconds: delay) {
                api.send(request: request, onComplete: onComplete)
            }
            self.lastSentAt += minimalInterval
        }
    }
}