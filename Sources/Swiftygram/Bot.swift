//
// Created by Zap on 07.08.2018.
//

import Foundation

final class Bot {

    typealias Token = String


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

        do {
            let request = try Method.getMe.request(for: token)
            api.send(request: request, onComplete: onComplete)
        } catch {
            onComplete(.failure(error))
        }
    }

    func send(
        message:             String,
        to:                  User.ID,
        additionalArguments: [String : Any] = [:],
        onComplete:          @escaping (Result<Message>) -> Void) {

        do {
            let request = try Method.sendMessage(to: to, text: message).request(for: token)
            api.send(request: request, onComplete: onComplete)

        } catch {
            onComplete(.failure(error))
        }
    }
}

