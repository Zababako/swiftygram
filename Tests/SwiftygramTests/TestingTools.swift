//
// Created by Zap on 10.08.2018.
//

import Foundation
import XCTest

extension String : Error {}

func test(action: () throws -> ()) {
    do { try action() }
    catch { XCTFail("Test failed - \(error)") }
}

extension XCTestCase {

    func testExpectation(
        _ description: String,
        timeout:       TimeInterval = 2,
        action:        (XCTestExpectation) throws -> ()
    )  {
        let exp = expectation(description: description)
        test { try action(exp) }
        waitForExpectations(timeout: timeout)
    }
}

