//
// Created by Zap on 25.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram

final class LimiterTests: XCTestCase {

    var limiter: Limiter!

    override func setUp() {
        super.setUp()

        limiter = Limiter()
    }

    func setUp(limit: Limiter.Limit) {
        setUp(limits: [limit])
    }

    func setUp(limits: [Limiter.Limit]) {
        setUp()
        limiter = Limiter(limits: Set(limits), targetQueue: .main)
    }

    func test_Limiter_without_limits_executes_actions_as_soon_as_it_gets_them() {

        for i in 0..<1000 {
            let iExpectation = expectation(description: "\(i) expectation will finish fast")
            limiter.execute {
                iExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_Limiter_with_limits_executes_the_first_action_as_soon_as_it_gets_one() {

        setUp(limit: Limiter.Limit(duration: 10, quantity: 1))

        let actionGetExecuted = expectation(description: "Action get executed right away")
        limiter.execute {
            actionGetExecuted.fulfill()
        }

        waitForExpectations(timeout: 0.5)
    }
}
