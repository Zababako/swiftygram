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

    func botInfo(onComplete: @escaping (Result<User>) -> Void) {

        do {
            let request = try composeRequest(for: .getMe, with: token)
            api.send(request: request, onComplete: onComplete)
        } catch {
            onComplete(.failure(error))
        }
    }
}