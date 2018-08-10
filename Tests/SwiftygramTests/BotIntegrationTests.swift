//
// Created by Zap on 06.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class BotIntegrationTests: XCTestCase {

    var bot: SwiftyBot!

    var updatesHolder: SubscriptionHolder?

    override func setUp() {
        super.setUp()

        let token = readFromEnvironment("TEST_BOT_TOKEN")

        if token == nil {
            XCTFail("Test is not prepared - no 'TEST_BOT_TOKEN' is not set")
        }

        bot = SwiftyBot(
            api:            APIClient(configuration: .ephemeral),
            pollingTimeout: 10,
            token:          token ?? "abc",
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

        waitForExpectations(timeout: 3)
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

            bot.send(message: "Running tests (\(Date()))", to: .id(info.id)) {
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

        waitForExpectations(timeout: 3)
    }

    func test_Bot_sends_message_to_its_owner() {

        guard let owner = readFromEnvironment("TEST_BOT_OWNER") else {
            XCTFail("'TEST_BOT_OWNER' is not set - nowhere to send message")
            return
        }
		
		guard let receiver = Receiver(value: owner) else {
            XCTFail("'TEST_BOT_OWNER' value \(owner) can not be converted into `Receiver`")
            return
        }

        let sendingFinishes = expectation(description: "Sending finishes")

        bot.send(message: "Running tests (\(Date()))", to: receiver) {
            result in

            sendingFinishes.fulfill()

            if case .failure(let error) = result {
                XCTFail("Sending doesn't fail with error: \(error)")
                return
            }
        }

        waitForExpectations(timeout: 3)
    }
}

