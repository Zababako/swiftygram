//
// Created by Zap on 06.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class BotTests: XCTestCase {

    var bot: Bot!
    var apiMock: APIMock!

    override func setUp() {
        super.setUp()

        apiMock = APIMock()

        bot = Bot(api: apiMock, token: "abc")
    }

    func test_Bot_receives_info_about_itself() {

        let requestFinishes = expectation(description: "Request finishes")

        bot.botInfo {
            result in

            XCTFail("TODO: Implement")
            requestFinishes.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_Bot_sends_message_to_itself() {
        XCTFail("TODO: Implement")
    }

    func test_Bot_receives_message() {
        XCTFail("TODO: Implement")
    }
}

final class APIMock: API {

    var t_storage: [URLRequest : Result<Any>] = [:]

    func send<T: Decodable>(request: URLRequest, onComplete: @escaping (Result<T>) -> Void) {

        guard let preparedResult = t_storage[request] else {
            XCTFail("Test preparation - result for: \(request) is prepared")
            return
        }

        guard case .success(let object) = preparedResult else {
            onComplete(preparedResult.map { $0 as! T})
            return
        }

        guard let castedObject = object as? T else {
            XCTFail("Test preparation - result for: \(request) has wrong Type")
            return
        }

        onComplete(.success(castedObject))
    }
}
