//
// Created by Zap on 06.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class BotIntegrationTests: XCTestCase {

    var bot: Bot!

    var updatesHolder: SubscriptionHolder?

    override func setUp() {
        super.setUp()

        let token = readFromEnvironment("TEST_BOT_TOKEN")

        if token == nil {
            XCTFail("Test is not prepared - no 'TEST_BOT_TOKEN' is not set")
        }

        let configuration: URLSessionConfiguration
        #if os(Linux)
        configuration = .default
        #else
        configuration = .ephemeral
        #endif

        bot = Bot(
            api:            APIClient(configuration: configuration),
            pollingTimeout: 10,
            token:          token ?? "abc",
            targetQueue:    nil,
            delegateQueue:  .main
        )
    }

    override func tearDown() {
        super.tearDown()

        updatesHolder = nil
    }

    func test_Bot_receives_info_about_itself() {

        let requestFinishes = expectation(description: "Request finishes")

        bot.getMe {
            result in

            requestFinishes.fulfill()

            guard case .success(let info) = result else {
                XCTFail("Request finishes successfully")
                return
            }

            XCTAssertGreaterThan(info.id, 0)
            XCTAssertNotNil(info.firstName)
            XCTAssertTrue(info.isBot)
        }

        waitForExpectations(timeout: 5)
    }

    func test_Bot_sends_message_to_itself_and_fail_because_it_is_forbidden() {

        let sendingFinishes = expectation(description: "Sending finishes")

        bot.getMe {
            [bot]
            result in

            guard case .success(let info) = result else {
                XCTFail("Could get selfInfo")
                return
            }

            guard let bot = bot else {
                XCTFail("Bot object is not destroyed")
                return
            }

            bot.send(message: "Running tests (\(Date()))", to: .id(info.id), parseMode: nil) {
                result in

                sendingFinishes.fulfill()

				guard case .failure(let error) = result else {
					XCTFail("Sending messages fails")
					return
				}

                guard let apiError = error as? APIError else {
                    XCTFail("Receives APIError")
                    return
                }
				
				guard let errorText = apiError.text else {
                    XCTFail("Error has text")
                    return
                }

                XCTAssertTrue(errorText.hasPrefix("Forbidden: "))
            }
        }

        waitForExpectations(timeout: 5)
    }

    func test_Bot_sends_message_to_its_owner() {

        testExpectation("Sending finishes") {
            expectation in

            bot.send(
                message:   "Running tests (\(Date()))",
                to:        try readOwner(),
                parseMode: nil
            ) {
                result in

                expectation.fulfill()

                test {
                    try result.onFailure { throw "Sending doesn't fail with error: \($0)" }
                              .onSuccess { message in
                                  guard let sender = message.from else { throw "No user in received message" }
                                  XCTAssertTrue(sender.isBot)
                              }
                }
            }
        }
    }
	
	func test_Bot_sends_file_to_its_owner_at_first_by_content_then_by_id() {

        testExpectation("Two sending finishes", timeout: 5) {
            expectation in

            let document = "Wow doc \(Date())".data(using: .utf8)!

            let owner = try readOwner()

            bot.send(
				document: .file(name:"document_test.txt", data: document),
                to:       owner,
                caption:  "Wow test"
            ) {
                [bot]
                result in

                test {
                    try result.onFailure { throw "Sending doesn't fail with error: \($0)" }

                    guard let message = result.value else {
                        throw "There is message in result"
                    }

                    guard let sender = message.from else { throw "No user in received message" }
                    XCTAssertTrue(sender.isBot)

                    guard let doc = message.document else { throw "No document in message sent" }
                    guard let filename = doc.fileName else { throw "Document has no name" }
                    XCTAssertEqual(filename, "document_test.txt")
                    XCTAssertEqual(message.caption, "Wow test")

                    bot!.send(
                        document: .reference(doc.fileId),
                        to:       owner
                    ) {
                        secondResult in

                        expectation.fulfill()
                        test {
                            try secondResult.onFailure { throw "Sending doesn't fail with error: \($0)" }

                            guard let secondMessage = secondResult.value else {
                                throw "There is message in result"
                            }

                            guard let secondDoc = secondMessage.document else { throw "No document in message sent" }
                            guard let secondFilename = secondDoc.fileName else { throw "Document has no name" }
                            XCTAssertEqual(secondFilename, "document_test.txt")
                            XCTAssertNil(message.text)
                        }
                    }
                }
            }
        }
    }

    func test_Bot_sends_message_with_keyboard_reply() {

        testExpectation("Sending finishes", timeout: 60) {
            expectation in

            let markup = ReplyMarkup.replyKeyboard(
                ReplyKeyboardMarkup(keyboard: [[
                    .plain("Push me"),
                    .requestContact("Contact?"),
                    .requestLocation("Location?")
                ]])
            )

            bot.send(
                message:     "Running tests (\(Date()))\nKeyboard reply expected",
                to:          try readOwner(),
                replyMarkup: markup
            ) {
                result in

                expectation.fulfill()

                test {
                    try result.onFailure { throw "Sending doesn't fail with error: \($0)" }
                              .onSuccess { message in
                                  guard let sender = message.from else { throw "No user in received message" }
                                  XCTAssertTrue(sender.isBot)
                              }
                }
            }
        }

    }
}

func readOwner() throws -> Receiver {

    guard let owner = readFromEnvironment("TEST_BOT_OWNER") else {
        throw "'TEST_BOT_OWNER' is not set - nowhere to send message"
    }

    guard let receiver = Receiver(value: owner) else {
        throw "'TEST_BOT_OWNER' value \(owner) can not be converted into `Receiver`"
    }

    return receiver
}
