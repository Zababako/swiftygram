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

private func ==(lhs: Holder, rhs: Holder) -> Bool {
    return lhs === rhs
}



private class Holder: SubscriptionHolder, Hashable {
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

final class SwiftyBot: Bot {


    // MARK: - Private properties

    private let api:   API
    private let token: Token

    private var subscriptionsRegistry: [Holder : (Update) -> Void] = [:]


    // MARK: - Initialization / Deinitialization

    init(api: API, token: Token) {
        self.api   = api
        self.token = token
    }


    // MARK: - Bot

    func subscribeToUpdates(handler: @escaping (Update) -> Void) -> SubscriptionHolder {

        return Holder()
    }

    func getMe(onComplete: @escaping (Result<User>) -> Void) {

        Result.action(handler: onComplete) {
            api.send(
                request: try Method.getMe.request(for: token),
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

        Result.action(handler: onComplete) {
            api.send(
                request: try Method.sendMessage(to: to, text: message)
                                   .request(for: token, with: additionalArguments),
                onComplete: $0
            )
        }
    }
}

