//
// Created by Zap on 10.08.2018.
//

import Foundation
import XCTest

extension String : Error {}

func test(file: StaticString = #file, line: UInt = #line, action: () throws -> ()) {
    do { try action() }
    catch { XCTFail("Test failed - \(error)") }
}

extension XCTestCase {

    func testExpectation(
        _ description: String,
        timeout:       TimeInterval = 2,
        file:          StaticString = #file,
        line:          UInt         = #line,
        action:        (XCTestExpectation) throws -> ()
    )  {
        let exp = expectation(description: description)
        test(file: file, line: line) { try action(exp) }
        waitForExpectations(timeout: timeout)
    }
}

