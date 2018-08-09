//
// Created by Zap on 08.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class BotTests: XCTestCase {

    var bot: Bot!

    var apiMock: APIMock!
    var holder: SubscriptionHolder?

    override func setUp() {
        super.setUp()

        apiMock = APIMock()

        bot = SwiftyBot(
            api:            apiMock,
            pollingTimeout: 10,
            token:          "123",
            delegateQueue:  .main
        )
    }

    func test_When_first_subscription_happens_updates_start() {

        let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!

        apiMock.t_storage[updateURL] = .success([Update(updateId: 1, message: nil, editedMessage: nil, channelPost: nil, editedChannelPost: nil)])
        let updateReceived = expectation(description: "Update received")

        holder = bot.subscribeToUpdates {
            _ in
            updateReceived.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_When_last_holder_is_released_updates_stop() {

		var counter = 0
        holder = bot.subscribeToUpdates { _ in
			counter
		}

        holder = nil
		
		bot.updatesErrorHandler {
			XCTFail("No error should happen \($0)")
		}

        // TODO: check that update requests are not sent to api anymore
    }


}
