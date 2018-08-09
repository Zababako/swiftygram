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

    func subscribeToUpdates(handler: @escaping (Update) -> Void) -> SubscriptionHolder
    var updatesErrorHandler: (Error) -> Void { get set }
}




private class Holder: SubscriptionHolder {}

final class SwiftyBot: Bot {


    // MARK: - Private properties

    private let api:   API
    private let token: Token

    private let pollingTimeout: TimeInterval

    private var offset: Update.ID?
    private var subscriptionsRegistry: [WeakBox<Holder> : (Update) -> Void] = [:] {
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

    func subscribeToUpdates(handler: @escaping (Update) -> Void) -> SubscriptionHolder {

        let holder = Holder()

        queue.async {
            self.subscriptionsRegistry[WeakBox(holder)] = handler
        }

        return holder
    }

    var updatesErrorHandler: (Error) -> Void = {
        print("Error happened during updates: \($0)")
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

    private func checkUpdates() {

        let timeout = Int(pollingTimeout)

        queue.async {
            [api, offset, token] in

            do {
                api.send(
                    request: try Method.GetUpdates(
                        offset:         offset,
                        limit:          nil,
                        timeout:        timeout,
                        allowedUpdates: nil
                    ).request(for: token)
                ) {
                    (result: Result<[Update]>) in

                    result
                        .onSuccess {
                            updates in

                            updates.forEach { update in
                                self.subscriptionsRegistry.values.forEach { handler in
                                    handler(update)
                                }
                            }
                        }
                        .onFailure {
                            self.updatesErrorHandler($0)
                        }
                }
            } catch {
                self.updatesErrorHandler(error)
            }
        }
    }
}

