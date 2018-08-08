//
// Created by Zap on 07.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


enum TestError: Error {
    case failedPreparation
}

final class APIMock: API {

    var t_storage: [URLRequest : Result<Any>] = [:]

    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void) {

        guard let preparedResult = t_storage[request] else {
            XCTFail("Test preparation - result for: \(request) is prepared")
            onComplete(.failure(TestError.failedPreparation))
            return
        }

        guard case .success(let object) = preparedResult else {
            onComplete(preparedResult.map { $0 as! T})
            return
        }

        guard let castedObject = object as? T else {
            XCTFail("Test preparation - result for: \(request) has wrong Type")
            onComplete(.failure(TestError.failedPreparation))
            return
        }

        onComplete(.success(castedObject))
    }
}



