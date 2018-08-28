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

        bot = Bot(
            api:            apiMock,
            pollingTimeout: 10,
            token:          "123",
            delegateQueue:  .main
        )
    }

    func test_When_first_subscription_happens_updates_start() {

        let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
        apiMock.t_storage[updateURL] = .success([Update()])

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

            assert(Thread.isMainThread)
			counter += 1
			guard counter == 3 else { return }
			
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

        let updateHappensThreeTimes = expectation(description: "Updates are received at least three times")
        var counter = 0

        holder = bot.subscribeToUpdates {
            result in

            if case .failure(let error) = result {
                XCTFail("Update doesn't fail with error: \(error)")
                return
            }

            counter += 1

            if counter == 3 {
                updateHappensThreeTimes.fulfill()
				self.holder = nil
            }
        }

        waitForExpectations(timeout: 3)
	}

    func test_On_each_update_bot_requests_update_after_the_last_one_received() {

        let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
        apiMock.t_storage[updateURL] = .success([Update(id: 5)])

		let updateRequestReceived = expectation(description: "Mock receives request to getUpdates")
		
        holder = bot.subscribeToUpdates {
            result in

            if case .failure(let error) = result {
                XCTFail("Update doesn't fail with error: \(error)")
                return
            }
			
			self.apiMock.t_onSend = {
                (request: URLRequest) in

                let getUpdatesDictionary = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String : Any]
                guard let offset = getUpdatesDictionary["offset"]! as? Int64 else {
                    XCTFail("\(getUpdatesDictionary["offset"]!) is Int64")
                    return
                }
				
				self.holder = nil

				updateRequestReceived.fulfill()
                XCTAssertEqual(offset, 6)
			}
        }

        waitForExpectations(timeout: 3)
    }
}

private extension Update {
	init(id: Update.ID = 1) {
		self.init(
			updateId: id,
			message: nil,
			editedMessage: nil,
			channelPost: nil,
			editedChannelPost: nil
		)
	}
}
