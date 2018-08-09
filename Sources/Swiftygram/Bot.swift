//
// Created by Zap on 07.08.2018.
//

import Foundation


public typealias Token = String

public protocol SubscriptionHolder: AnyObject {}

public protocol Bot {

    func getMe(onComplete: @escaping (Result<User>) -> Void)
    func send(
        message:             String,
        to:                  Receiver,
        additionalArguments: [String : Any],
        onComplete:          @escaping (Result<Message>) -> Void
    )

    func subscribeToUpdates(handler: @escaping (Result<[Update]>) -> Void) -> SubscriptionHolder
}




private class Holder: SubscriptionHolder {}

final class SwiftyBot: Bot {


    // MARK: - Private properties

    private let api:   API
    private let token: Token

    private let pollingTimeout: TimeInterval

    private var offset: Update.ID?
    private var subscriptionsRegistry: [WeakBox<Holder> : (Result<[Update]>) -> Void] = [:] {
        didSet {
            subscriptionsRegistry = subscriptionsRegistry.filter { (box, _) in box.value != nil }
            isUpdating = !subscriptionsRegistry.isEmpty
        }
    }
    private var isUpdating: Bool = false {
        didSet {
            guard isUpdating != oldValue else { return }

            if isUpdating { checkUpdates() }
        }
    }

    private let queue: DispatchQueue = DispatchQueue(label: "swiftygram.bot")
    private let delegateQueue: DispatchQueue


    // MARK: - Initialization / Deinitialization

    /// parameter pollingTimeout - should be the same as timeout in URLSessionConfiguration in API
    init(api: API, pollingTimeout: TimeInterval, token: Token, delegateQueue: DispatchQueue) {
        self.api            = api
        self.pollingTimeout = pollingTimeout
        self.token          = token
        self.delegateQueue  = delegateQueue
    }


    // MARK: - Bot

    func subscribeToUpdates(handler: @escaping (Result<[Update]>) -> Void) -> SubscriptionHolder {

        let holder = Holder()

        queue.async {
            self.subscriptionsRegistry[WeakBox(holder)] = handler
        }

        return holder
    }

    func getMe(onComplete: @escaping (Result<User>) -> Void) {

        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try Method.GetMe().request(for: token),
                onComplete: $0
            )
        }
    }

    func send(
        message:             String,
        to:                  Receiver,
        additionalArguments: [String : Any] = [:],
        onComplete:          @escaping (Result<Message>) -> Void
    ) {

        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try Method.SendMessage(chatId: to, text: message).request(for: token),
                onComplete: $0
            )
        }
    }


    // MARK: - Private Methods

    private func propagateUpdateResult(_ result: Result<[Update]>) {

        subscriptionsRegistry = subscriptionsRegistry.filter { (box, _) in box.value != nil }

        subscriptionsRegistry.forEach { (_, handler) in
            delegateQueue.async { handler(result) }
        }
    }

    private func checkUpdates() {

        // Asserting this code is performed on self.queue

        let timeout = Int(pollingTimeout)

        do {
            api.send(
                request: try Method.GetUpdates(
                    offset:         offset,
                    limit:          nil,
                    timeout:        timeout,
                    allowedUpdates: nil
                ).request(for: token)
            ) {
                [queue]
                (result: Result<[Update]>) in

                queue.async {
                    result.onSuccess {
                        updates in

                        if let last = updates.last {
                            self.offset = last.updateId.next
                        }
                    }

                    self.propagateUpdateResult(result)

                    if self.isUpdating {
                        self.checkUpdates()
                    }
                }
            }
        } catch {
            propagateUpdateResult(.failure(error))
        }
    }
}

