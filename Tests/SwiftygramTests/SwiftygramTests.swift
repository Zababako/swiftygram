import XCTest
@testable import Swiftygram

final class SwiftygramTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Swiftygram().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
