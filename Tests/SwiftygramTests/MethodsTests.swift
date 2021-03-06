//
// Created by Zap on 07.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram

final class MethodsTests: XCTestCase {

	func test_Conversion_from_Method_Struct_name_to_API_path_works() {
		
		XCTAssertEqual(APIMethod.GetMe().path, "getMe")
		XCTAssertEqual(APIMethod.GetUpdates().path, "getUpdates")
		XCTAssertEqual(APIMethod.SendMessage(chatId: "@random_chat", text: "brb").path, "sendMessage")
        XCTAssertEqual(APIMethod.SendDocument(chatId: "@chat", document: .reference("fileid1")).path, "sendDocument")
	}

    func test_Send_Document_encodes_arguments_into_multipart_form_data() {

        test {
            let fileData = "random file data".data(using: .utf8)!
			let method = APIMethod.SendDocument(chatId: "@chat", document: .file(name:"test.txt", data: fileData))

            let request = try method.request(for: "token1")

            guard let contentType = request.value(forHTTPHeaderField: "Content-type") else {
                throw "Content-type request header was not specified"
            }

            XCTAssertNotNil(contentType.range(of: "multipart/form-data"))

            guard let body = request.httpBody else {
                throw "Formed request has body"
            }

            XCTAssertNotNil(body)

            // TODO: test body
        }
    }

    /// https://core.telegram.org/bots/api#making-requests
    func test_URL_is_composed_as_described_in_document() {

        do {
            let request = try APIMethod.GetMe().request(for: "123abc")

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
