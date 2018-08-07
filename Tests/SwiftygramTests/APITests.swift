//
// Created by Zap on 06.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram

private struct Dummy: Codable {}


final class APITests: XCTestCase {

    private var api: APIClient!

    override func setUp() {
        super.setUp()

        api = APIClient()
    }

    func test_API_parses_error() {

        let url = URL(string: "https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/getMe")!
        let request = URLRequest(url: url)

        let requestFinishes = expectation(description: "Request sending finishes")

        api.send(request: request) {
            (result: Result<Dummy>) in

            guard case .failure(let error) = result else {
                XCTFail("Request fails")
                return
            }

            guard let _ = error as? APIError else {
                XCTFail("APIError is parsed")
                return
            }

            requestFinishes.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func test_API_parses_success() {
        XCTFail("TODO: Implement")
    }
}

