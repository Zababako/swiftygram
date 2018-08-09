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
		apiMock.t_storage[updateURL] = .success([Update(updateId: 1, message: nil, editedMessage: nil, channelPost: nil, editedChannelPost: nil)])

		let timePasses = expectation(description: "Time passes")

		var lastUpdateStamp = Date().timeIntervalSince1970
        holder = bot.subscribeToUpdates { result in

			lastUpdateStamp = Date().timeIntervalSince1970
			
            if case .failure(let error) = result {
				XCTFail("Update doesn't fail with error: \(error)")
                return
            }
        }
		
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
			
			self.holder = nil
			let releaseStamp = Date().timeIntervalSince1970

			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
				timePasses.fulfill()
				XCTAssertGreaterThan(releaseStamp, lastUpdateStamp)
			}
		}
		
		waitForExpectations(timeout: 3)
    }
	
	func test_Updates_are_requested_infinitely() {
		XCTFail("TODO: implement")
	}
}
