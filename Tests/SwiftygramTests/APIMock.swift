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

    var t_storage: [URL : Result<Any>] = [:]
	var t_onSend: (URLRequest) -> Void = { _ in }

    var t_queue: DispatchQueue = DispatchQueue(label: "com.zababako.swiftygram.tests.apimock")

    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void) {

		t_onSend(request)

        let finalizer: (Result<T>) -> Void = {
            [t_queue] result in t_queue.async { onComplete(result) }
        }

        guard let preparedResult = t_storage[request.url!] else {
            XCTFail("Test preparation - result for: \(request.url!) is prepared")
            finalizer(.failure(TestError.failedPreparation))
            return
        }

        guard case .success(let object) = preparedResult else {
            finalizer(preparedResult.map { $0 as! T})
            return
        }

        guard let castedObject = object as? T else {
            XCTFail("Test preparation - result for: \(request.url!) has wrong Type")
            finalizer(.failure(TestError.failedPreparation))
            return
        }

        finalizer(.success(castedObject))
    }
}



