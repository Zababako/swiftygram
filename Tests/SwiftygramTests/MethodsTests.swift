//
// Created by Zap on 07.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram

final class MethodsTests: XCTestCase {

	func test_Conversion_from_Method_Struct_name_to_API_path_works() {
		
		XCTAssertEqual(Method.GetMe().path, "getMe")
		XCTAssertEqual(Method.GetUpdates(offset: nil, limit: nil, timeout: nil, allowedUpdates: nil).path, "getUpdates")
		XCTAssertEqual(Method.SendMessage(chatId: "@somechat", text: "brb").path, "sendMessage")
	}
	
    /// https://core.telegram.org/bots/api#making-requests
    func test_URL_is_composed_as_described_in_document() {

        do {
            let request = try Method.GetMe().request(for: "123abc")

            guard let expectedURL = URL(string: "https://api.telegram.org/bot123abc/getMe") else {
                XCTFail("Test preparation - expectedURL is composed")
                return
            }

            guard let unexpectedURL = URL(string: "https://api.telegram.org/123abc/getMe") else {
                XCTFail("Test preparation - unexpectedURL is composed")
                return
            }

            XCTAssertEqual(request.url, expectedURL)
            XCTAssertNotEqual(request.url, unexpectedURL)
        } catch {
            XCTFail("Error doesn't happen: \(error)")
        }
    }
}
