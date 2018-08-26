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

        limiter = Limiter(targetQueue: .main)
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

    func test_only_N_first_actions_are_executed_when_limit_is_reached() {

        let maxQuantity = 10

        setUp(limit: Limiter.Limit(duration: 60, quantity: maxQuantity))

		var counter: Set<Int> = Set<Int>()
        for i in 0..<1000 {
            XCTAssert(Thread.isMainThread, "Test setup failed - mutations should happen on one thread")
            limiter.execute { counter.insert(i) }
        }

        let secondPassed = expectation(description: "Second passes")
        DispatchQueue.main.asyncAfter(seconds: 1) {
            secondPassed.fulfill()
            XCTAssertEqual(counter, Set(0..<maxQuantity))
        }

        waitForExpectations(timeout: 2)
    }

    func test_Two_limits_are_both_respected() {

        setUp(
            limits: [
                Limiter.Limit(duration: 60, quantity: 10),
				Limiter.Limit(duration: 20, quantity: 5),
            ]
        )

        var counter: Set<Int> = Set<Int>()
        for i in 0..<100 {
            XCTAssert(Thread.isMainThread, "Test setup failed - mutations should happen on one thread")
            limiter.execute {
				counter.insert(i)
			}
        }

        let secondPassed = expectation(description: "Second passes")
        DispatchQueue.main.asyncAfter(seconds: 1) {
            secondPassed.fulfill()
            XCTAssertEqual(counter, Set(0..<min(5, 10)))
        }

        waitForExpectations(timeout: 2)
    }
}
