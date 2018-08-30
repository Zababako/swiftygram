//
// Created by Zap on 01.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class ToolsTests: XCTestCase {

    func test_Environmental_variable_is_loaded_from_environment() {

        prepareEnvVar(key: "RANDOM_VARIABLE", value: "abc")
        XCTAssertEqual(readFromEnvironment("RANDOM_VARIABLE"), "abc")
    }

    func test_Environmental_variable_is_loaded_from_file() {
        
        prepareFile(key: "test", value: "File content")
        XCTAssertEqual(readFromEnvironment("test"), "File content")
    }

    func test_Environmental_variable_tries_to_load_value_from_environment_first_and_then_from_file() {

        prepareEnvVar(key: "direct_order", value: "ab1")
        prepareFile(key: "direct_order", value: "ab2")

        XCTAssertEqual(readFromEnvironment("direct_order"), "ab1")

        prepareFile(key: "revert_order", value: "ab3")
        prepareEnvVar(key: "revert_order", value: "ab4")

        XCTAssertEqual(readFromEnvironment("revert_order"), "ab4")
    }
}

private func prepareEnvVar(key: String, value: String) {
    setenv(key, value, 1)
}

private func prepareFile(key: String, value: String) {

    guard let testFileURL = URL(string: "file://\(FileManager.default.currentDirectoryPath)/\(key)") else {
        XCTFail("Failed to convert path to URL")
        return
    }

    do {
        try value.write(to: testFileURL, atomically: true, encoding: .utf8)
    } catch {
        XCTFail("Test setup error - couldn't write content to file: \(error)")
    }
}
