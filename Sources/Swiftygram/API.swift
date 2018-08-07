//
// Created by Zap on 07.08.2018.
//

import Foundation


protocol API {
    func send<T: Decodable>(request: URLRequest, onComplete: (Result<T>) -> Void)
}

struct APIError: Error {
    let text: String?
    let code: Int?
}

extension APIError {
    init() {
        self.text = nil
        self.code = nil
    }
}


final class APIClient: API {


    // MARK: - API

    func send<T: Decodable>(request: URLRequest, onComplete: (Result<T>) -> Void) {

        onComplete(.failure(APIError()))
    }
}