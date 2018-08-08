//
// Created by Zap on 06.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram

private struct Dummy: Codable {}


final class APIIntegrationTests: XCTestCase {

    private var api: APIClient!

    override func setUp() {
        super.setUp()

        api = APIClient(configuration: .ephemeral)
    }

    func test_API_parses_error() {

        let url = URL(string: "https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/getMe")!
        let request = URLRequest(url: url)

        let requestFinishes = expectation(description: "Request sending finishes")

        api.send(request: request) {
            (result: Result<Dummy>) in

            requestFinishes.fulfill()

            guard case .failure(let error) = result else {
                XCTFail("Request fails")
                return
            }

            guard let apiError = error as? APIError else {
                XCTFail("APIError is parsed")
                return
            }

            XCTAssertEqual(apiError.text, "Unauthorized")
        }

        waitForExpectations(timeout: 2)
    }

    func test_API_parses_success() {

        guard let token = readFromEnvironment("TEST_BOT_TOKEN") else {
            XCTFail("Test environment is not configured, missing value for 'TEST_BOT_TOKEN'")
            return
        }

        let url = URL(string: "https://api.telegram.org/bot\(token)/getMe")!
        let request = URLRequest(url: url)

        let requestFinishes = expectation(description: "Request sending finishes")

        api.send(request: request) {
            (result: Result<User>) in

            requestFinishes.fulfill()

            guard case .success = result else {
                XCTFail("Request succeeds")
                return
            }
        }

        waitForExpectations(timeout: 5)
    }
}

