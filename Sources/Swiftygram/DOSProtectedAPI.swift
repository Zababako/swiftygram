//
// Created by Zap on 22.08.2018.
//

import Foundation


final internal class DOSProtectedAPI: API {


    // MARK: - Private properties

    private let api:     API
    private let limiter: Limiter


    // MARK: - Initialization / Deinitialization

    internal init(
        api:     API,
        limiter: Limiter
    ) {
        self.api     = api
        self.limiter = limiter
    }


    // MARK: - API

    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void) {

        limiter.execute {
            [api] in
            api.send(request: request, onComplete: onComplete)
        }
    }
}