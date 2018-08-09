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
}




private class Holder: SubscriptionHolder {}

final class SwiftyBot: Bot {


    // MARK: - Private properties

    private let api:   API
    private let token: Token

    private var offset: Update.ID?
    private var subscriptionsRegistry: [WeakBox<Holder> : (Update) -> Void] = [:] {
        didSet {
            // TODO: if added first holder - start updates

            // TODO: if removed last holder - end updates
        }
    }

    private let queue: DispatchQueue = DispatchQueue(label: "swiftygram.bot")
    private let delegateQueue: DispatchQueue


    // MARK: - Initialization / Deinitialization

    init(api: API, token: Token, delegateQueue: DispatchQueue) {
        self.api           = api
        self.token         = token
        self.delegateQueue = delegateQueue
    }


    // MARK: - Bot

    func subscribeToUpdates(handler: @escaping (Update) -> Void) -> SubscriptionHolder {

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

    private func checkUpdates() {

    }
}

