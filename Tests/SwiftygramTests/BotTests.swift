//
// Created by Zap on 06.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


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


enum TestError: Error {
    case failedPreparation
}

final class BotTests: XCTestCase {

    var bot:     Bot!
    var apiMock: APIMock!

    override func setUp() {
        super.setUp()

        apiMock = APIMock()

        bot = Bot(api: apiMock, token: "abc")
    }

    func test_Bot_receives_info_about_itself() {

        let requestFinishes = expectation(description: "Request finishes")

        bot.getMe {
            result in

            requestFinishes.fulfill()

            XCTFail("TODO: Implement")
        }

        waitForExpectations(timeout: 1)
    }

    func test_Bot_sends_message_to_itself() {

        let sendingFinishes = expectation(description: "Sending finishes")

        bot.getMe {
            [bot]
            result in

            guard case .success(let info) = result else {
                XCTFail("Could get selfInfo")
                return
            }

            bot!.send(message: "Ping", to: info.id) {
                result in

                sendingFinishes.fulfill()

                guard case .success = result else {
                    XCTFail("Could send message")
                    return
                }
            }
            XCTFail("TODO: Implement")
        }

        waitForExpectations(timeout: 5)
    }

    func test_Bot_receives_message() {
        XCTFail("TODO: Implement")
    }
}

