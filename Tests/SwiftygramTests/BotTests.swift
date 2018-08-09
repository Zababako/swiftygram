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
            delegateQueue:  DispatchQueue.global()
        )
    }

    func test_When_first_subscription_happens_updates_start() {

        let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
        apiMock.t_storage[updateURL] = .success([Update(updateId: 1, message: nil, editedMessage: nil, channelPost: nil, editedChannelPost: nil)])

		let updateReceived = expectation(description: "Update received")
		updateReceived.assertForOverFulfill = false

        holder = bot.subscribeToUpdates {
            _ in
            updateReceived.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_When_last_holder_is_released_updates_stop() {

		let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
		apiMock.t_storage[updateURL] = .success([Update()])
		
		var counter = 0
		let timePassesAfterUnsubscription = expectation(description: "Time passes")

		holder = bot.subscribeToUpdates {
			result in
			
			if case .failure(let error) = result {
				XCTFail("Update doesn't fail with error: \(error)")
				return
			}
			
			counter += 1
			guard counter >= 3 else { return }
			
			self.holder = nil
			
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
				timePassesAfterUnsubscription.fulfill()
				XCTAssertEqual(counter, 3)
			}
		}
		
		waitForExpectations(timeout: 3)
    }
	
	func test_Updates_are_requested_infinitely() {

		let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
		apiMock.t_storage[updateURL] = .success([Update()])

        let updateHappensThreeTimes = expectation(description: "Updates are received three times")
        var counter = 0

        holder = bot.subscribeToUpdates {
            result in

            if case .failure(let error) = result {
                XCTFail("Update doesn't fail with error: \(error)")
                return
            }

            counter += 1

            if counter >= 3 {
                updateHappensThreeTimes.fulfill()
            }
        }

        waitForExpectations(timeout: 3)
	}
}

private extension Update {
	init() {
		self.init(
			updateId: 1,
			message: nil,
			editedMessage: nil,
			channelPost: nil,
			editedChannelPost: nil
		)
	}
}
