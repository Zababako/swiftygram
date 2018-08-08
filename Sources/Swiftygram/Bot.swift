//
// Created by Zap on 07.08.2018.
//

import Foundation


public enum Receiver {
    case id(ReceiverID)
    case username(String)
}

public typealias ReceiverID = Int64

public protocol Bot {
    func getMe(onComplete: @escaping (Result<User>) -> Void)
    func send(
        message:             String,
        to:                  Receiver,
        additionalArguments: [String : Any],
        onComplete:          @escaping (Result<Message>) -> Void
    )
}

public typealias Token = String


final class SwiftyBot: Bot {


    // MARK: - Private properties

    let api: API
    let token: Token


    // MARK: - Initialization / Deinitialization

    init(api: API, token: Token) {
        self.api   = api
        self.token = token
    }


    // MARK: - Bot

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
                request: try Method.sendMessage(to: to, text: message).request(for: token),
                onComplete: $0
            )
        }
    }
}

