//
// Created by Zap on 08.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram


final class BotTests: XCTestCase {

    var bot: Bot!

    var apiMock:     APIMock!
    var token:       SubscriptionToken?
    var targetQueue: DispatchQueue!

    override func setUp() {
        super.setUp()

        apiMock = APIMock()
        targetQueue = DispatchQueue(label: "com.zababako.bot.tests")

        bot = Bot(
            api:            apiMock,
            pollingTimeout: 10,
            token:          "123",
            targetQueue:    targetQueue,
            delegateQueue:  .main
        )
    }

    override func tearDown() {
        super.tearDown()

        if let subscribedToken = token {
            bot.unsubscribeFromUpdates(token: subscribedToken)
        }

        apiMock = nil
        bot     = nil
        token   = nil
    }

    func test_When_first_subscription_happens_updates_start() {

        let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
        apiMock.t_storage[updateURL] = .success([Update()])

		let updateReceived = expectation(description: "Update received")
        #if os(Linux)
        var updateReceivedFlag = false
        #else
        updateReceived.assertForOverFulfill = false
        #endif

        token = bot.subscribeToUpdates {
            _ in
            #if os(Linux)
            if !updateReceivedFlag { updateReceived.fulfill() }
            updateReceivedFlag = true
            #else
            updateReceived.fulfill()
            #endif
        }

        waitForExpectations(timeout: 5)
    }

    func test_Updates_do_not_come_after_unsubscription() {

		let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
		apiMock.t_storage[updateURL] = .success([Update()])
		
		var counter = 0
		let timePassesAfterUnsubscription = expectation(description: "Time passes")

        token = bot.subscribeToUpdates {
			result in

			if case .failure(let error) = result {
				XCTFail("Update doesn't fail with error: \(error)")
				return
			}

            assert(Thread.isMainThread)
			counter += 1
			guard counter == 3 else { return }

            self.bot!.unsubscribeFromUpdates(token: self.token!)

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

        let updateHappensManyTimes = expectation(description: "Updates are received at least ten times")
        var counter                = 0

        token = bot.subscribeToUpdates {
            result in

            if case .failure(let error) = result {
                XCTFail("Update doesn't fail with error: \(error)")
                return
            }

            assert(Thread.isMainThread)

            counter += 1

            if counter == 10 {
                updateHappensManyTimes.fulfill()
                self.bot.unsubscribeFromUpdates(token: self.token!)
            }
        }

        waitForExpectations(timeout: 3)
	}

    func test_On_each_update_bot_requests_update_after_the_last_one_received() {

        let updateURL = URL(string: "https://api.telegram.org/bot123/getUpdates")!
        apiMock.t_storage[updateURL] = .success([Update(id: 5)])

		let updateRequestReceived = expectation(description: "Mock receives request to getUpdates")

        token = bot.subscribeToUpdates {
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

                self.bot.unsubscribeFromUpdates(token: self.token!)

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
