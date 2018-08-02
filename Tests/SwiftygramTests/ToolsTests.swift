//
// Created by Zap on 01.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class ToolsTests: XCTestCase {

    func test_Environmental_variable_is_loaded_from_environment() {

        setenv("RANDOM_VARIABLE", "abc", 1)

        guard let value = readFromEnvironment("RANDOM_VARIABLE") else {
            XCTFail("Variable is read from environment")
            return
        }

        XCTAssertEqual(value, "abc")
    }

    func test_Environmental_variable_is_loaded_from_file() {

        do {
            try "abcd".write(to: URL(string:"file://test")!, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Test setup - \(error)")
        }

        guard let value = readFromEnvironment("test") else {
            XCTFail("Variable is read from file")
            return
        }

        XCTAssertEqual(value, "abcd")
    }
}
